#!/bin/ash
# Read values
i2cset -r -y 0 0x17 0xf0 0x03 b
HRST_VALUE=$(( (($(i2cget -y 0 0x17 0x02) & 0x07) << 8) + $(i2cget -y 0 0x17 0x01) ))
LEFT_VALUE=$(( ( (($(i2cget -y 0 0x17 0x05) & 0x0f) << 8) + $(i2cget -y 0 0x17 0x04) +1) ))
RIGHT_VALUE=$(( ( ($(i2cget -y 0 0x17 0x06) << 4) + ($(i2cget -y 0 0x17 0x05) >> 4) +1) ))
if [ $LEFT_VALUE -eq $HRST_VALUE ]
then
    LEFT_VALUE=0
fi
if [ $RIGHT_VALUE -eq $HRST_VALUE ]
then
    RIGHT_VALUE=0
fi
# File adjust
LOW=$((LEFT_VALUE & 0xff))
MED=$(( ((RIGHT_VALUE & 0x00F) << 4) + (LEFT_VALUE >> 8) ))
HIGH=$(( RIGHT_VALUE >> 4 ))
sed -i 773c\\$LOW /home/$USER/gbs-control/settings/defaults/current.set
sed -i 774c\\$MED /home/$USER/gbs-control/settings/defaults/current.set
sed -i 775c\\$HIGH /home/$USER/gbs-control/settings/defaults/current.set
# Register adjust
i2cset -r -y -m 0x0f 0 0x17 0x05 $((LEFT_VALUE >> 8))
i2cset -r -y -m 0xff 0 0x17 0x04 $((LEFT_VALUE & 0xFF))
i2cset -r -y -m 0xff 0 0x17 0x06 $((RIGHT_VALUE >> 4))
i2cset -r -y -m 0xf0 0 0x17 0x05 $(( (RIGHT_VALUE & 0x00F) << 4))
	