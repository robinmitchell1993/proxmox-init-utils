#!/bin/bash
#
set -u

# max of n numbers
function max() {
  [[ $# > 0 ]] || {
    echo "Warning: max takes minimum one argument"
    return 1
  }

  local rs=0 # return status
  local max="$1"
  shift

  for n in "$@"; do
    max=$(( "$n" > "$max" ? "$n" : "$max" ))
    rs=$(( $? > $rs ? $? : $rs ))
  done

  printf '%d' $max
  return $(( $? > $rs ? $? : $rs ))
}


SENSORNAME="Temp"
THRESHOLD_COLD=27
THRESHOLD_COOL=30
THRESHOLD_WARM=35
THRESHOLD_HOT=40
THRESHOLD_DANGER=45

# Get temperatures
T=$(ipmitool sdr type temperature | grep $SENSORNAME | cut -d"|" -f5 | cut -d" " -f2)
echo "-- current temperature --" $(max $T)

# Thresholds

# Too Cold threshold / turn off all fans
if [[ $(max $T) < $THRESHOLD_COLD ]]
  then
    # Disable Dynamic Fan
    ipmitool raw 0x30 0x30 0x01 0x00
   
    # Turn off fan
    ipmitool raw 0x30 0x30 0x02 0xff 0x00
fi

# Cold threshold
if [[ $(max $T) > $THRESHOLD_COLD ]]
  then
    # Disable Dynamic Fan
    ipmitool raw 0x30 0x30 0x01 0x00
   
    # Turn fan low
    ipmitool raw 0x30 0x30 0x02 0xff 0x06
fi

# Cool threshold
if [[ $(max $T) > $THRESHOLD_COOL ]]
  then
    # Disable Dynamic Fan
    ipmitool raw 0x30 0x30 0x01 0x00
   
    # Turn fan low
    ipmitool raw 0x30 0x30 0x02 0xff 0x15
fi

# Warm threshold
if [[ $(max $T) > $THRESHOLD_WARM ]]
  then
    # Disable Dynamic Fan
    ipmitool raw 0x30 0x30 0x01 0x00
   
    # Turn fan low
    ipmitool raw 0x30 0x30 0x02 0xff 0x20
fi

# Hot threshold
if [[ $(max $T) > $THRESHOLD_HOT ]]
  then
    # Disable Dynamic Fan
    ipmitool raw 0x30 0x30 0x01 0x00
   
    # Turn fan low
    ipmitool raw 0x30 0x30 0x02 0xff 0x35
fi

# DANGER ZONE
if [[ $(max $T) > $THRESHOLD_DANGER ]]
  then
    # Enable Dynamic Fan
    ipmitool raw 0x30 0x30 0x01 0x01
fi