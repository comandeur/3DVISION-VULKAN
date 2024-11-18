local lfs = require("lfs")  -- Requires LuaFileSystem, which is usually bundled with Lua or ZeroBrane

-- Determine the directory where the script is located
local current_path = debug.getinfo(1).source:match("@?(.*[/\\])")

-- Set the working directory to the script's location
if lfs.chdir(current_path) then
    print("Changed working directory to: " .. current_path)
else
    error("Failed to change working directory to: " .. current_path)
end

-- Update package.path to include the current directory for loading Lua modules
package.path = package.path .. ";" .. current_path .. "?.lua"

-- Import the USBControl module
local USBControl = require("USBControl")

-- Attempt to initialize libusb
local success, err = pcall(function()
    USBControl.init({})  -- No specific options provided
end)

-- Check if initialization was successful
if not success then
    print("Error during libusb initialization: " .. tostring(err))
else
    print("libusb initialized successfully in test script.")
end

-- Cleanup the libusb context before exiting
USBControl.cleanup()
