Reverse engineering of the NVIDIA 3D Vision 

People have reversed engineered nvidia 3D vision before to bypass the nvidia drivers to use it on linux. As the era of 3D tech has been behind us, most of theses repos were for 2010-2013 linux.

The aim of this project is to do an up to date app that will work crossplatform, for any screen, for any computeur, with minimal performance impact.

To achieve this, multiple decision has been made:

- LuaJIT 32bit, ce app will be entirely in LuaJIT, being able to be really fast and use FFI to call other package at C type speed
- Libusb, like repo has made before, the USB control for the nivida 3D vision IR emitor has been know, using liusb with a basic win mounted driver will make easy to control the IR emitor through FFI calls
- 
