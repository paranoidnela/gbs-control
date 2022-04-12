#!/bin/ash

# File adjust
LOW=$(sed -n '792p' /home/$USER/gbs-control/settings/defaults/current.set)
HIGH=$(sed -n '793p' /home/$USER/gbs-control/settings/defaults/current.set)
NEW_VALUE=$(( ( (($HIGH & 0x7f) << 4) + ($LOW >> 4) -1) ))
HIGH=$(( ((NEW_VALUE >> 4) & 0x7f) + ($HIGH & 0x80) ))
LOW=$(( ((NEW_VALUE << 4) & 0xf0) + ($LOW & 0x0f) ))
sed -i 792c\\$LOW /home/$USER/gbs-control/settings/defaults/current.set
sed -i 793c\\$HIGH /home/$USER/gbs-control/settings/defaults/current.set
# Register adjust
i2cset -r -y 0 0x17 0xf0 0x03 b 
NEW_VALUE=$(( ( (($(i2cget -y 0 0x17 0x18) & 0x7f) << 4) + ($(i2cget -y 0 0x17 0x17) >> 4) -1) )) 
i2cset -r -y -m 0x7f 0 0x17 0x18 $((NEW_VALUE >> 4))
i2cset -r -y -m 0xf0 0 0x17 0x17 $(( (NEW_VALUE & 0x00F) << 4))
