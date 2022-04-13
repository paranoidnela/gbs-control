gbs-control
===========

RaspberryPi control interface that acts as i2c master to control the Trueview5725 in cheap scaler boards and allows running custom modes.

Scripts for controlling and applying new custom settings on Trueview5725 based video processors such as the GBS8200, GBS8220, and maybe others in the future (HD Box Pro) using a Raspberry Pi.

**INSTALL GUIDE**

The install script is designed to be used with a fresh vanilla Raspbian Lite install, the new Raspbian images require the user to create their own accounts on first boot, the user can be named anything you want.  
to install or update run the following command (I highly reccomend to take a look at the script before blindly executing it):  

`curl https://raw.githubusercontent.com/paranoidbashthot/gbs-control/master/install-gbs-control.sh | bash`

**Usage**

On the Raspberry Pi side: connect two wires on the composite out, connectthe three i2c wires to the GPIO pins, connect a keyboard(you can make a custom keypad) to usb and connect a power source.  
On the scaler side: bridge P8 (this will disable the stock control circuit), connect the composite out of the Pi to the Y RCA on the scaler (green jack), connect the i2c to the P5 connector on the scaler.  
RGBS (scart) to the scaler: the best solution is use the the header P11, R G and B are direct connections, CSync should go to a LM1881N but for testing I am skipping this and just pulling CSync down to ground with a 75ohm and connecting it to the scaler using a 470ohm which while not perfect is good enough for testing. NOTE: all video ground should be tied together using this method, you can get audio and connect it directly to the TV/converter/audio system.  
TODO: add pictures.  

**Hotkeys**

Navigation:

F1	-	Switch to Pi Menu

F2	-	Switch to Currently loaded settings

F5  -   Quick save settings

F7  -   Quick load settings

Grave/Tilde(`/~)+1 - Switch menu to RGBHV 480p (VGA)

Grave/Tilde(`/~)+2 - Switch menu to YPbPr 480p

Grave/Tilde(`/~)+3 - Switch menu to RGBHV 576p (Non-standard)

Grave/Tilde(`/~)+4 - Switch menu to YPbPr 576p

Fine adjustments:

CTRL+1	-	Increase vertical scale (if enabled)

CTRL+2	-	Decrease vertical scale (if enabled)

CTRL+3	-	Decrease horizontal scale

CTRL+4	-	Increase horizontal scale

CTRL+5	-	Move image up

CTRL+6	-	Move image down

CTRL+7	-	Move image left

CTRL+8	-	Move image right
