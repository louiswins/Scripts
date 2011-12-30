#!/bin/bash

# Requires dzen2 and dmplex.
# Battery widget       requires acpi
# Wireless widget      requires wireless_tools
# Volume widget        requires alsa-utils and inotify-tools
# CPU Frequency widget requires cpufrequtils

# dzen2 options
DZEN_HOME="$HOME/.dzen2"
FG='#aaaaaa'
BG='#1a1a1a'
SCREEN_WIDTH=1366
BAR_WIDTH=500
FONT='-*-terminus-*-r-normal-*-12-*-*-*-*-*-iso8859-*'

# icons
ICON_PATH="$DZEN_HOME/icons"
ICON_WIRELESS="^i($ICON_PATH/wireless.xpm)"
ICON_AC="^i($ICON_PATH/ac.xpm)"
ICON_BATTERY="^i($ICON_PATH/battery.xpm)"
ICON_VOLUME="^i($ICON_PATH/vol.xpm)"
ICON_MUTED="^i($ICON_PATH/mute.xpm)"
ICON_CPUFREQ="^i($ICON_PATH/cpu.xpm)"
ICON_TIME="^i($ICON_PATH/time.xpm)"

# pipe for dmplex
PIPE="$DZEN_HOME/dmpipe"
PIDFILE="$DZEN_HOME/info-bar.sh.pid"


# Usage: update_bar position icon text
update_bar () {
	local widget_sep=" :: "
	local icon_sep=" "
	if [ $1 -eq 1 ]; then
		widget_sep=
	fi
	echo $1 "$widget_sep$2$icon_sep$3" >"$PIPE"
}



update_time () {
	while true; do
		update_bar $1 "$ICON_TIME" "$(date '+%a %-d %b %Y ^fg(white)%H:%M^fg():%S')"
		sleep 1
	done
}

update_battery() {
	local bat_text
	local bat_icon
	while true; do
		bat_text="$(acpi -b)"
		if acpi -a | grep -q on-line; then
			bat_icon="$ICON_AC"
		else
			bat_icon="$ICON_BATTERY"
		fi

		if echo $bat_text | grep -q remaining || echo $bat_text | grep -q 'until charged'; then
			bat_text="$(echo $bat_text | sed -rn 's/.* ([0-9]+%), ([0-9]{2}:[0-9]{2}).*/\1 (\2)/p')"
		elif echo $bat_text | grep -q unavailable; then
			bat_text="$(echo $bat_text | sed -rn 's/.* ([0-9]+%), .*/\1 (unknown)/p')"
		elif echo $bat_text | grep -q Full; then
			bat_text='100% (Full)'
		else
			bat_text='No battery'
		fi

		update_bar $1 "$bat_icon" "$bat_text"
		sleep 20
	done
}

update_wireless () {
	while true; do
		update_bar $1 "$ICON_WIRELESS" "$(iwconfig wlan0 | awk '/Quality/{print $2}' | cut -d'=' -f2 | awk -F'/' '{printf("%.0f%%", $1/$2*100)}')"
		sleep 5
	done
}

update_volume() {
	local vol
	local vol_icon
	while true; do
		vol="$(amixer get Master | grep Mono:)"
		if echo $vol | grep -q off; then
			vol_icon="$ICON_MUTED"
		else
			vol_icon="$ICON_VOLUME"
		fi
		# clickable areas for muting, increasing, and decreasing volume
		vol_icon="^ca(1, amixer set Master toggle)^ca(4, amixer set Master 5+ unmute)^ca(5, amixer set Master 5-)$vol_icon"
		vol="$(echo $vol | sed -r 's/.*[0-9] \[([0-9]+)%.*/\1/' | gdbar -h 10 -w 30 -fg '#aaaaaa' -bg '#565656')^ca()^ca()^ca()"

		update_bar $1 "$vol_icon" "$vol"
		inotifywait -t 30 -qq /dev/snd/controlC0
	done
}

update_cpufreq () {
	while true; do
		update_bar $1 "$ICON_CPUFREQ" "$(printf '%3.2f GHz' $(echo 2k$(cpufreq-info -f) 1000000/p | dc))"
		sleep 2
	done
}

# create pipe
rm -f "$PIPE" >/dev/null 2>&1
mkfifo "$PIPE" >/dev/null 2>&1
if [ ! -p "$PIPE" ]; then
	echo "Could not create named pipe $PIPE; execution failed." >&2
	exit 1
fi

# kill old processes if they exist
if [ -f "$PIDFILE" ]; then
	for pid in "$(cat "$PIDFILE")"; do
		kill $pid 2>/dev/null
	done
	: > "$PIDFILE" # truncate $PIDFILE
fi

update_wireless 1 & echo $! >> "$PIDFILE"
update_battery  2 & echo $! >> "$PIDFILE"
update_volume   3 & echo $! >> "$PIDFILE"
update_cpufreq  4 & echo $! >> "$PIDFILE"
update_time     5 & echo $! >> "$PIDFILE"
# I like to have a space at the end
echo "1023  " >"$PIPE" &

{ tail -f "$PIPE" & echo $! >>"$PIDFILE" ; } | dmplex | dzen2 -e '' -w $BAR_WIDTH -x $(($SCREEN_WIDTH - $BAR_WIDTH)) -h 12 -ta r -fg $FG -bg $BG -fn $FONT &
