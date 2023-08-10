#!/bin/ash
# Install script for Trueview 5725 control (GBS8200, GBS8220, HD9000, HD Box Pro etc)

DIR=$HOME"/gbs-control"
echo -e "\nInstall location is: "$DIR

# Update sources and install I2C components.
echo -e "\nUpdating sources & installing i2c utils:"
sudo apt-get update
sudo apt-get install -y i2c-tools libi2c-dev python3-smbus git

# Get latest stable version from GitHub
echo -e "\nDownloading current master version:"
cd $HOME
rm -r gbs-control
git clone https://github.com/paranoidnela/gbs-control.git
chmod +x $(find /home/$USER/gbs-control/ | grep "\.sh")

# Patch /etc/modules for i2c use, blacklist is obsolete and config.txt seemingly gets auto patched
echo -e "\nApply patch to /etc/modules for kernal i2c modules:"
sudo patch -bN -F 6 /etc/modules $DIR/scripts/patch.modules
sudo usermod -aG i2c $USER

# Patch /etc/default/triggerhappy to use current user
echo -e "\nApply patch to /etc/default/triggerhappy to use current user"
sudo sed -i 's/^.*DAEMON_OPTS=.*$/DAEMON_OPTS="--user '$USER'"/' /etc/default/triggerhappy
# This is necessary because of a "bug" where the defaults config gets ignored, it might cause issues in the future
sudo sed -i 's/^.*--user.*$/ExecStart=\/usr\/sbin\/thd --triggers \/etc\/triggerhappy\/triggers.d\/ --socket \/run\/thd.socket --user '$USER' --deviceglob \/dev\/input\/event*/' /lib/systemd/system/triggerhappy.service

# Check Raspberry PI Revision to move triggerhappy files to /etc/triggerhappy/triggers.d and patch scripts correctly
echo -e "\nCopy triggerhappy hotkey conf files:"
REVISION=$(cat /proc/cpuinfo | grep Revision)
LEN=${#REVISION}
POS=$((LEN -4))
REV=${REVISION:POS}
if [ "$REV" = "Beta" ] || [ "$REV" = "0002" ] || [ "$REV" = "0003" ]; then
    echo -e "Revision 1 detected"
	sudo cp $DIR/thd/triggerhappy_rev1/* /etc/triggerhappy/triggers.d/
	sed -i 's/    self.bus = smbus.SMBus(1)/    self.bus = smbus.SMBus(0)/' $DIR/scripts/Adafruit_I2C.py
else
    echo -e "Revision 2 detected"
	sudo cp $DIR/thd/triggerhappy/* /etc/triggerhappy/triggers.d/
fi
sudo systemctl enable triggerhappy
echo $USER > installeduser
sudo mv installeduser /installeduser

# Add required scripts for automatic start-up.
echo -e "\nApply patch to .profile for bootup scripts:"
patch -bN -F 6 $HOME/.profile $DIR/scripts/patch.profile
cat $DIR/scripts/override.conf > /etc/systemd/system/getty@tty1.service.d/override.conf
echo "ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin $USER %I \$TERM" >> /etc/systemd/system/getty@tty1.service.d/override.conf

# Replace config.txt to ensure booting with composite.
echo -e "\nReplace /boot/config.txt for Luma output settings:"
sudo cp /boot/config.txt /boot/config.txt.bak
sudo rm /boot/config.txt
# Check for Device tree usage
DEVTREE=$(ls /proc | grep -c device-tree)
if [ "$DEVTREE" = "0" ]; then
    echo -e "No Device Tree detected"
	sudo cp $DIR/scripts/config.txt /boot/config.txt
else
    echo -e "Device Tree detected"
	sudo cp $DIR/scripts/config-device-tree.txt /boot/config.txt
fi

# Reboot
echo -e "\nNow rebooting system"
sync
sudo reboot
exit 0
