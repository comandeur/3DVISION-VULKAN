local ffi = require("ffi")

ffi.cdef[[
    typedef struct libusb_context libusb_context;

    int libusb_init(libusb_context **ctx);
    void libusb_exit(libusb_context *ctx);
]]

ffi.load("C:\\Users\\flore\\Documents\\N3DRV\\libusb-1.0.dll")