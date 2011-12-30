#!/bin/sh
# Prints out various system information.

# folding@home "unitinfo.txt" file (leave blank or as an invalid file to disable)
UNITINFO="/opt/fah/unitinfo.txt"

clear

# System information + logins
uname -snrmpio
w
echo

# disk usage
df -h 2>/dev/null | grep '^\(/dev\| \)'
echo

echo -n 'CPU Frequency: '; cpufreq-info -fm
echo

# folding@home status
if [ -f "$UNITINFO" ]; then
	echo F@H: Protein $(sed -n '3s/Name: //p' < $UNITINFO) :: $(tail -n 1 $UNITINFO)
	echo
fi

fortune
echo
