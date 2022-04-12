#!/bin/bash
END=$(sed -n 1p /home/$USER/gbs-control/settings/defaults/end)
while [ "$END" == "false" ]; do
  END=$(sed -n 1p /home/$USER/gbs-control/settings/defaults/end)
  REVISION=$(cat /proc/cpuinfo | grep Revision)
  LEN=${#REVISION}
  POS=$((LEN -4))
  REV=${REVISION:POS}
if [ "$REV" = "Beta" ] || [ "$REV" = "0002" ] || [ "$REV" = "0003" ]; then
    I2C_PORT=$((0))
  else
    I2C_PORT=$((1))
  fi
  SETTING=$(sed -n 1p /home/$USER/gbs-control/settings/defaults/current.dei)
  RUNNING=$(sed -n 1p /home/$USER/gbs-control/settings/defaults/running)
  # Pull in new Settings
  OFFSET=$(( $(sed -n 2p /home/$USER/gbs-control/settings/defaults/current.dei) ))
  DETECT_SCAN=$(sed -n 3p /home/$USER/gbs-control/settings/defaults/current.dei)
  DETECT_LINES=$(( $(sed -n 4p /home/$USER/gbs-control/settings/defaults/current.dei) ))
  NORMAL_SCAN=$(sed -n 5p /home/$USER/gbs-control/settings/defaults/current.dei)
  if [ "$DETECT_SCAN" == "interlaced" ]; then
    # Match is interlaced, Mismatch is progressive
    MATCH=$((0x01))
	  MISMATCH=$((0x00))
  else
    # Match is progressive, Mismatch is interlaced
    MATCH=$((0x00))
	  MISMATCH=$((0x01))
  fi
  TEST=$(( -1 ))
  
  LOW=$(sed -n '771p' /home/$USER/gbs-control/settings/defaults/current.set)
  MED=$(sed -n '772p' /home/$USER/gbs-control/settings/defaults/current.set)
  VDS_VRST=$(( (($MED & 0x7f) << 4) + ($LOW >> 4) ))

  #Process Running Loop
  while [ "$RUNNING" == "true" ] && [ "$SETTING" == "true" ] && [ "$END" == "false" ]; do
	  SETTING=$(sed -n 1p /home/$USER/gbs-control/settings/defaults/current.dei)
    RUNNING=$(sed -n 1p /home/$USER/gbs-control/settings/defaults/running)
    END=$(sed -n 1p /home/$USER/gbs-control/settings/defaults/end)
    
    LOW=$(( $(sed -n '776p' /home/$USER/gbs-control/settings/defaults/current.set) ))
    MED=$(( $(sed -n '777p' /home/$USER/gbs-control/settings/defaults/current.set) ))
    HIGH=$(( $(sed -n '778p' /home/$USER/gbs-control/settings/defaults/current.set) ))
    VDS_VTOP=$(( ( ($MED & 0x07) << 8) + $LOW ))
    VDS_VBOTTOM=$(( ( ($HIGH & 0x7f) << 4) + ($MED >> 4) ))
    
    IF_VPOS=$(( $(sed -n 287p /home/$USER/gbs-control/settings/defaults/current.set) ))
    IF_VOFFSET=$(($OFFSET))
    if [ $(( $IF_VPOS + $OFFSET )) -lt $((0)) ]; then
      IF_VOFFSET=$((-1 * $IF_VPOS))
      
      VDS_VTOP_OFFSET=$(( $VDS_VTOP - $OFFSET - $IF_VPOS ))
      if [ "$VDS_VTOP_OFFSET" -lt $((0)) ]; then
        VDS_VTOP_OFFSET=$(( $VDS_VTOP_OFFSET + $VDS_VRST))
      elif [ "$VDS_VTOP_OFFSET" -ge "$VDS_VRST" ]; then
        VDS_VTOP_OFFSET=$(( $VDS_VTOP_OFFSET - $VDS_VRST))
      fi
      
      VDS_VBOTTOM_OFFSET=$(( $VDS_VBOTTOM - $OFFSET - $IF_VPOS ))
      if [ "$VDS_VBOTTOM_OFFSET" -lt $((0)) ]; then
        VDS_VBOTTOM_OFFSET=$(( $VDS_VBOTTOM_OFFSET + $VDS_VRST))
      elif [ "$VDS_VBOTTOM_OFFSET" -ge "$VDS_VRST" ]; then
        VDS_VBOTTOM_OFFSET=$(( $VDS_VBOTTOM_OFFSET - $VDS_VRST))
      fi
    else
      VDS_VTOP_OFFSET=$VDS_VTOP
      VDS_VBOTTOM_OFFSET=$VDS_VBOTTOM
    fi
    
    i2cset -y $I2C_PORT 0x17 0xf0 0x00
    PREVIOUS=$(( $TEST ))
    TEST=$(( (($(i2cget -y $I2C_PORT 0x17 0x08) & 0x0F ) << 7) + ($(i2cget -y $I2C_PORT 0x17 0x07) >> 1) ))
    if (( "$TEST" != "$PREVIOUS" )); then
      echo "match is: "$DETECT_SCAN", normal is: "$NORMAL_SCAN
      if (( "$TEST" == "$DETECT_LINES" )); then
        # Match
        i2cset -y -r $I2C_PORT 0x17 0xf0 0x04
        i2cset -y -r -m 0x01 $I2C_PORT 0x17 0x4a $MATCH
  		  i2cset -y -r $I2C_PORT 0x17 0xf0 0x01
        if [ "$DETECT_SCAN" == "$NORMAL_SCAN" ]; then
          echo "Match and normal"
          i2cset -y -r -m 0xff $I2C_PORT 0x17 0x1e $IF_VPOS
          i2cset -r -y 1 0x17 0xf0 0x03 b
          i2cset -r -y -m 0x07 $I2C_PORT 0x17 0x08 $((VDS_VTOP >> 8))
          i2cset -r -y -m 0xff $I2C_PORT 0x17 0x07 $((VDS_VTOP & 0xFF))
          i2cset -r -y -m 0x7f $I2C_PORT 0x17 0x09 $((VDS_VBOTTOM >> 4))
          i2cset -r -y -m 0xf0 $I2C_PORT 0x17 0x08 $(( (VDS_VBOTTOM & 0x00F) << 4))
        else
          echo "Match and not normal"
          i2cset -y -r -m 0xff $I2C_PORT 0x17 0x1e $(($IF_VPOS + $IF_VOFFSET))
          i2cset -r -y 1 0x17 0xf0 0x03 b
          i2cset -r -y -m 0x07 $I2C_PORT 0x17 0x08 $((VDS_VTOP_OFFSET >> 8))
          i2cset -r -y -m 0xff $I2C_PORT 0x17 0x07 $((VDS_VTOP_OFFSET & 0xFF))
          i2cset -r -y -m 0x7f $I2C_PORT 0x17 0x09 $((VDS_VBOTTOM_OFFSET >> 4))
          i2cset -r -y -m 0xf0 $I2C_PORT 0x17 0x08 $(( (VDS_VBOTTOM_OFFSET & 0x00F) << 4))
        fi
      else
        # Mismatch
        i2cset -y -r $I2C_PORT 0x17 0xf0 0x04
        i2cset -y -r -m 0x01 $I2C_PORT 0x17 0x4a $MISMATCH
  		  i2cset -y -r $I2C_PORT 0x17 0xf0 0x01
        if [ "$DETECT_SCAN" != "$NORMAL_SCAN" ]; then
          i2cset -y -r -m 0xff $I2C_PORT 0x17 0x1e $IF_VPOS
          i2cset -r -y 1 0x17 0xf0 0x03 b
          i2cset -r -y -m 0x07 $I2C_PORT 0x17 0x08 $((VDS_VTOP >> 8))
          i2cset -r -y -m 0xff $I2C_PORT 0x17 0x07 $((VDS_VTOP & 0xFF))
          i2cset -r -y -m 0x7f $I2C_PORT 0x17 0x09 $((VDS_VBOTTOM >> 4))
          i2cset -r -y -m 0xf0 $I2C_PORT 0x17 0x08 $(( (VDS_VBOTTOM & 0x00F) << 4))
          echo "Mismatch and not normal"
        else
          i2cset -y -r -m 0xff $I2C_PORT 0x17 0x1e $(($IF_VPOS + $IF_VOFFSET))
          i2cset -r -y 1 0x17 0xf0 0x03 b
          i2cset -r -y -m 0x07 $I2C_PORT 0x17 0x08 $((VDS_VTOP_OFFSET >> 8))
          i2cset -r -y -m 0xff $I2C_PORT 0x17 0x07 $((VDS_VTOP_OFFSET & 0xFF))
          i2cset -r -y -m 0x7f $I2C_PORT 0x17 0x09 $((VDS_VBOTTOM_OFFSET >> 4))
          i2cset -r -y -m 0xf0 $I2C_PORT 0x17 0x08 $(( (VDS_VBOTTOM_OFFSET & 0x00F) << 4))
          echo "Mismatch and normal"
        fi
      fi
    fi
    sleep 0.5
  done
  sleep 0.5
done

exit 0
