#!/usr/bin/env bash

theme=${HOME}/.zui/current_theme/rofi/powermenu.rasi

# CMDs
uptime="$(uptime -p | sed -e 's/up //g')"

# Options
hibernate=''
shutdown='⏻'
reboot='󰑐'
lock='󰌾'
suspend='󰒲'
logout='󰍃'
yes=''
no='󰜺'

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p " ${USER}    󰒋 ${HOSTNAME}" \
		-mesg "󰔟 ${uptime}" \
		-theme "${theme}"
}

# Confirmation CMD
confirm_cmd() {
	rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 350px;}' \
		-theme-str 'mainbox {orientation: vertical; children: [ "message", "listview" ];}' \
		-theme-str 'listview {columns: 2; lines: 1;}' \
		-theme-str 'element-text {horizontal-align: 0.5;}' \
		-theme-str 'textbox {horizontal-align: 0.5;}' \
		-dmenu \
		-p 'Confirmation' \
		-mesg 'Are you Sure?' \
		-theme "${theme}"
}

# Ask for confirmation
confirm_exit() {
	echo -e "${yes}\n${no}" | confirm_cmd
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "${lock}\n${suspend}\n${logout}\n${hibernate}\n${reboot}\n${shutdown}" | rofi_cmd
}

# Execute Command
run_cmd() {
	if [[ $1 == '--shutdown' ]]; then
		systemctl poweroff
	elif [[ $1 == '--reboot' ]]; then
		systemctl reboot
	elif [[ $1 == '--hibernate' ]]; then
		systemctl hibernate
	elif [[ $1 == '--suspend' ]]; then
		mpc -q pause
		amixer set Master mute
		systemctl suspend
	elif [[ $1 == '--logout' ]]; then
		bspc quit
	fi
}

# Actions
chosen="$(run_rofi)"
echo "${chosen}"
case "${chosen}" in
	"${shutdown}")
		run_cmd --shutdown
		;;
	"${reboot}")
		run_cmd --reboot
		;;
	"${hibernate}")
		run_cmd --hibernate
		;;
	"${lock}")
		"${HOME}/.zui/core/system/modules/lock/interface.sh"
		;;
	"${suspend}")
		run_cmd --suspend
		;;
	"${logout}")
		run_cmd --logout
		;;
esac
