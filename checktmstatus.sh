#!/bin/sh

isConfigured=false
isMounted=false


#output, when no TM configured: tmutil: No destinations configured


#tmutil destinationinfo | grep "Mount Point" | sed 's/.*: //'
theTMVolume="tmutil destinationinfo | grep 'Mount Point' | sed 's/.*: //'"
eval $theTMVolume

if [ $? == 0 ]; then
  echo "Configured properly"
  isConfigured=true
else
  echo "Not configured"
fi


tmVolume="TimeMachine"

# Check if configured TM volume is mounted
#mount | grep "/Volumes/TimeMachine" &> /dev/null
mount | grep "/Volumes/$tmVolume" &> /dev/null
if [ $? == 0 ]; then
  echo "TM volume mounted"
  isMounted=true
else
  echo "TM volume not mounted"
fi


# If previous checks passed, check if tmutil is running
if [ $isConfigured == true ] && [ $isMounted == true ]; then
  tmutil status | grep 'Running = 1' &> /dev/null
  if [ $? == 0 ]; then
    echo "Running"
  else
    echo "NOT running"
  fi
else
  echo "TM Volume not configured and/or not mounted"
fi
