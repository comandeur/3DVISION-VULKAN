-- Import the FFI library
local ffi = require("ffi")

-- Function to determine the current path when built as an executable
local function get_exe_path()
    local sep = package.config:sub(1, 1)  -- Get the path separator for the current OS
    local str = debug.getinfo(1).source:match("@?(.*[/\])") or "./"
    if sep == '\\' then
        str = str:gsub('/', '\\')
    end
    return str
end

-- Determine the path to the DLL
local dll_path = get_exe_path() .. "libusb-1.0.dll"
print("Determined DLL path: " .. dll_path)

-- Define the libusb C functions and types we need
ffi.cdef[[
    typedef void* libusb_context;
    typedef void* libusb_device_handle;

    typedef enum {
        LIBUSB_OPTION_LOG_LEVEL = 0,
        LIBUSB_OPTION_USE_USBDK = 1
    } libusb_init_option;

    int libusb_init_context(libusb_context **ctx, const libusb_init_option options[], int num_options);
    void libusb_exit(libusb_context *ctx);

    libusb_device_handle* libusb_open_device_with_vid_pid(libusb_context *ctx, uint16_t vendor_id, uint16_t product_id);
    int libusb_claim_interface(libusb_device_handle *dev_handle, int interface_number);
    int libusb_release_interface(libusb_device_handle *dev_handle, int interface_number);
    int libusb_bulk_transfer(libusb_device_handle *dev_handle, unsigned char endpoint, unsigned char *data, int length, int *transferred, unsigned int timeout);
    void libusb_close(libusb_device_handle *dev_handle);
]]

-- Load the libusb shared library with error handling
print("Attempting to load libusb DLL...")
local success, libusb = pcall(ffi.load, dll_path)
if not success then
    error("Failed to load libusb-1.0.dll from path: " .. dll_path .. " - " .. tostring(libusb))
else
    print("Successfully loaded libusb DLL.")
end

-- Create a table to represent our USBControl module
local USBControl = {}

-- Initialize libusb context
function USBControl.init(options)
    if USBControl.ctx ~= nil then
        return  -- libusb is already initialized.
    end

    local ctx = ffi.new("libusb_context *[1]")
    local options_array = nil
    local num_options = 0

    -- Set options if provided
    if options and #options > 0 then
        options_array = ffi.new("libusb_init_option[?]", #options, options)
        num_options = #options
    end
    
    local result = libusb.libusb_init_context(ctx, options_array, num_options)
    
    if result ~= 0 then
        error("Failed to initialize libusb. Error code: " .. result)
    end

    USBControl.ctx = ctx[0]  -- Store the context in the module
end

-- Cleanup function to close libusb context
function USBControl.cleanup()
    if USBControl.ctx ~= nil then
        libusb.libusb_exit(USBControl.ctx)
        USBControl.ctx = nil
    end
end

-- Function to initialize the USB device
function USBControl.init_IR(vendor_id, product_id)
    print("Initializing USB device...")
    if USBControl.ctx == nil then
        error("libusb is not initialized.")
    end

    -- Open the device with the given vendor and product ID
    local dev_handle = libusb.libusb_open_device_with_vid_pid(USBControl.ctx, vendor_id, product_id)
    if dev_handle == nil then
        error("Failed to open USB device with VID: " .. vendor_id .. " PID: " .. product_id)
    end

    -- Claim interface 0 (assuming it is the correct one)
    local result = libusb.libusb_claim_interface(dev_handle, 0)
    if result ~= 0 then
        libusb.libusb_close(dev_handle)
        error("Failed to claim interface 0. Error code: " .. result)
    end

    -- Send initialization data sequences
    USBControl.send_init(dev_handle)

    -- Release the interface and close the device
    libusb.libusb_release_interface(dev_handle, 0)
    libusb.libusb_close(dev_handle)
    print("USB device initialized successfully.")
end

-- Function to send initialization data sequences
function USBControl.send_init(dev_handle)
    -- Function to send data to endpoint 0x02
    local function send_data(data)
        local data_len = #data
        local data_array = ffi.new("unsigned char[?]", data_len, data)
        local transferred = ffi.new("int[1]")
        local timeout = 1000  -- 1 second timeout

        local result = libusb.libusb_bulk_transfer(dev_handle, 0x02, data_array, data_len, transferred, timeout)
        if result ~= 0 then
            error("Failed to send data to endpoint 0x02. Error code: " .. result)
        end
        print("Sent " .. transferred[0] .. " bytes to endpoint 0x02.")
    end

    -- Send the sequences of bytes as per the initialization requirements
    send_data({0x42, 0x18, 0x03, 0x00})
    send_data({0x01, 0x00, 0x18, 0x00, 0x91, 0xED, 0xFE, 0xFF, 0x33, 0xD3, 0xFF, 0xFF, 0xC6, 0xD7, 0xFF, 0xFF, 0x30, 0x28, 0x24, 0x22, 0x0A, 0x08, 0x05, 0x04, 0x52, 0x79, 0xFE, 0xFF})
    send_data({0x01, 0x1C, 0x02, 0x00, 0x02, 0x00})
    send_data({0x01, 0x1E, 0x02, 0x00, 0xF0, 0x00})
    send_data({0x01, 0x1B, 0x01, 0x00, 0x07})
    send_data({0x40, 0x18, 0x03, 0x00})
end

-- Return the USBControl module
return USBControl
