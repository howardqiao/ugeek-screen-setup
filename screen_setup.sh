#!/bin/bash
BLACKLIST="/etc/modprobe.d/raspi-blacklist.conf"
CONFIG="/boot/config.txt"
FBCP="/usr/local/bin/fbcp"
SPEED="80000000"
ROTATE="90"
FPS="60"
RESOLUTION="640*480"
HDMIGROUP="2"
HDMIMODE="4"
HDMICVT=""
OUTPUT_DEVICE="BOTH"
SCREEN_BLANKING="No"
TITLE="UGEEK WORKSHOP"
BACKTITLE="UGEEK WORKSHOP [ ugeek.aliexpress.com | ukonline2000.taobao.com ]"

function enable_tft(){
	#enable spi:dtparam=spi=on
	#sed -i 's/.*dtparam=spi=.*/dtparam=spi=on/g' $CONFIG
	disable_tft
	sed -i '/^dtparam=spi/d' $CONFIG
	echo "dtparam=spi=on" >> $CONFIG
	echo "dtoverlay=pitft22,speed=$SPEED,rotate=$ROTATE,fps=$FPS" >> $CONFIG
	if [ -n "$HDMIGROUP" ]; then
		echo "hdmi_group=$HDMIGROUP" >> $CONFIG
	fi
	if [ -n "$HDMIMODE" ]; then
		echo "hdmi_mode=$HDMIMODE" >> $CONFIG
	fi
	if [ -n "$HDMICVT" ]; then
		echo "hdmi_cvt=$HDMICVT" >> $CONFIG
	fi
	echo "hdmi_force_hotplug=1" >> $CONFIG
}
function disable_tft(){
	#disable pitft overlay
	sed -i '/^dtoverlay=pitft22/d' $CONFIG
	sed -i '/^hdmi_mode=/d' $CONFIG
	sed -i '/^hdmi_group=/d' $CONFIG
	sed -i '/^hdmi_cvt=/d' $CONFIG
	sed -i '/^hdmi_force_hotplug=/d' $CONFIG
}
function enable_cmdline_tft(){
	FBONCONFIGED=$(cat /boot/cmdline.txt | grep "fbcon=map:10")
	if [ -z "$FBONCONFIGED" ]; then
		sed -i -e 's/rootwait/rootwait fbcon=map:10 fbcon=font:VGA8x8/' /boot/cmdline.txt
	fi
}
function disable_cmdline_tft(){
	#sed -i -e 's/rootwait fbcon=map:10 fbcon=font:VGA8x8/rootwait/' /boot/cmdline.txt
	sed -i -e 's/fbcon=map:10 //' /boot/cmdline.txt
	sed -i -e 's/fbcon=font:VGA8x8 //' /boot/cmdline.txt

}
function enable_blanking(){
	disable_blanking
	sed -i '/^sh -c "TERM=linux/d' /etc/rc.local
	sed -i -e 's/^xserver-command=X -s 0 dpms/#xserver-command=X/' /etc/lightdm/lightdm.conf
}
function disable_blanking(){
	sed -i '/exit 0/ish -c "TERM=linux setterm -blank 0 >/dev/tty0"' /etc/rc.local
	sed -i -e 's/^#xserver-command=X/xserver-command=X -s 0 dpms/' /etc/lightdm/lightdm.conf
}
function enable_tftx(){
	if [ -e "/usr/share/X11/xorg.conf.d/99-fbturbo.conf" ] ; then
		rm /usr/share/X11/xorg.conf.d/99-fbturbo.conf
	fi
	touch /usr/share/X11/xorg.conf.d/99-fbturbo.conf
	cat << EOF > /usr/share/X11/xorg.conf.d/99-fbturbo.conf
Section "Device"
  Identifier "Adafruit PiTFT"
  Driver "fbdev"
  Option "fbdev" "/dev/fb1"
EndSection
EOF
}
function disable_tftx(){
	if [ -e "/usr/share/X11/xorg.conf.d/99-fbturbo.conf" ] ; then
		rm /usr/share/X11/xorg.conf.d/99-fbturbo.conf
	fi
	touch /usr/share/X11/xorg.conf.d/99-fbturbo.conf
	cat << EOF > /usr/share/X11/xorg.conf.d/99-fbturbo.conf
Section "Device"
        Identifier      "Allwinner A10/A13 FBDEV"
        Driver          "fbturbo"
        Option          "fbdev" "/dev/fb0"

        Option          "SwapbuffersWait" "true"
EndSection
EOF
}
function disable_fbcp(){
	sed -i '/^\/usr\/local\/bin\/fbcp/d' /etc/rc.local
}
function enable_fbcp(){
	if [ -e "$FBCP" ]; then
		echo ""
	else
		wget https://github.com/howardqiao/zpod/raw/master/zpod_res/fbcp -O $FBCP
		chmod +x $FBCP
	fi
	disable_fbcp
	sed -i '/exit 0/i\/usr\/local\/bin\/fbcp &' /etc/rc.local
}
menu_outputdevice(){
	OPTION_OUTPUT=$(whiptail --title "OUTPUT DEVICE" \
	--backtitle "$BACKTITLE" \
	--nocancel \
	--menu "OUTPUT DEVICE:$OUTPUT_DEVICE" \
	--default-item "3" \
	14 60 3 \
	"1" "HDMI" \
	"2" "TFT Screen" \
	"3" "HDMI & TFT Screen" 3>&1 1>&2 2>&3)
	return $OPTION_OUTPUT
}
menu_resolution(){
	OPTION_RES=$(whiptail --title "SCREEN RESOLUTION" \
	--backtitle "$BACKTITLE" \
	--nocancel \
	--menu "Screen resolution:$RESOLUTION" \
	--default-item "3" \
	14 60 4 \
	"1" "Auto" \
	"2" "800*600" \
	"3" "640*480" \
	"4" "320*240" 3>&1 1>&2 2>&3)
	return $OPTION_RES
}
menu_rotate(){
	OPTION_ROTATE=$(whiptail --title "SCREEN ROTATE" \
	--menu "Screen rotate:$ROTATE°" \
	--backtitle "$BACKTITLE" \
	--nocancel \
	--default-item "2" \
	14 60 4 \
	"1" "0°" \
	"2" "90°" \
	"3" "180°" \
	"4" "270°" 3>&1 1>&2 2>&3)
	return $OPTION_ROTATE
}
function menu_blanking(){
	OPTION_BLANKING=$(whiptail --title "SCREEN BLANKING" \
	--menu "Screen blanking:$SCREEN_BLANKING" \
	--backtitle "$BACKTITLE" \
	--nocancel \
	--default-item "2" \
	14 60 2 \
	"1" "Enable" \
	"2" "Disble" 3>&1 1>&2 2>&3)
	return $OPTION_BLANKING
}
function menu_reboot(){
	if (whiptail --title "$TITLE" \
		--yes-button "Reboot" \
		--no-button "Exit" \
		--yesno "Reboot system to apply new settings?" 10 60) then
		reboot
	else
		exit 1
	fi
}
function menu_main(){
	OPTION=$(whiptail --title "$TITLE" \
	--menu "Select the appropriate options:" \
	--backtitle "$BACKTITLE" \
	--nocancel \
	14 60 6 \
	"1" "Output <$OUTPUT_DEVICE>." \
	"2" "Resolution <$RESOLUTION>." \
	"3" "Rotate <$ROTATE°>." \
	"4" "Blanking <$SCREEN_BLANKING>." \
	"5" "Apply new settings." \
	"6" "Exit."  3>&1 1>&2 2>&3)
	return $OPTION
}
function apply_hdmi(){
	disable_tft
	disable_cmdline_tft
	disable_tftx
	disable_fbcp
}
function apply_tft(){
	RESOLUTION="320*240"
	HDMIGROUP="2"
	HDMIMODE="87"
	HDMICVT="320 240 60 1 0 0 0"
	enable_tft
	enable_cmdline_tft
	enable_tftx
	disable_fbcp
}
function apply_both(){
	enable_tft
	disable_cmdline_tft
	disable_tftx
	enable_fbcp
}
function apply(){
	case $OUTPUT_DEVICE in
		"HDMI")
		apply_hdmi
		;;
		"TFT")
		apply_tft
		;;
		"BOTH")
		apply_both
		;;
	esac
	case $SCREEN_BLANKING in 
		"Yes")
		enable_blanking
		;;
		"No")
		disable_blanking
		;;
	esac
	menu_reboot
}
if [ $UID -ne 0 ]; then
	whiptail --title "UGEEK WORKSHOP" \
	--msgbox "Superuser privileges are required to run this script.\ne.g. \"sudo $0\"" 10 60
    exit 1
fi
# whiptail --title "$TITLE" --msgbox "Setup tools for ugeek screens.\nhttp://ugeek.aliexpress.com\nhttp://ukonline2000.taobao.com" --backtitle "$BACKTITLE" 10 60
while true
do
menu_main
case $? in
	1)
	menu_outputdevice
	case $? in
		1)
		OUTPUT_DEVICE="HDMI"
		RESOLUTION="Auto"
		;;
		2)
		OUTPUT_DEVICE="TFT"
		RESOLUTION="320x240"
		;;
		3)
		OUTPUT_DEVICE="BOTH"
		;;
	esac
	;;
	2)
	if [ "$OUTPUT_DEVICE" = "BOTH" ]; then
		menu_resolution
		case $? in 
			1)
			RESOLUTION="Auto"
			;;
			2)
			RESOLUTION="800x600"
			;;
			3)
			RESOLUTION="640x480"
			;;
			4)
			RESOLUTION="320x240"
			;;
		esac
	fi
	;;
	3)
	if [ "$OUTPUT_DEVICE" != "HDMI" ]; then
		menu_rotate
		case $? in 
			1)
			ROTATE="0"
			;;
			2)
			ROTATE="90"
			;;
			3)
			ROTATE="180"
			;;
			4)
			ROTATE="270"
			;;
		esac
	fi
	;;
	4)
	menu_blanking
	case $? in 
		1)
		SCREEN_BLANKING="Yes"
		;;
		2)
		SCREEN_BLANKING="No"
		;;
	esac
	;;
	5)
	apply
	;;
	6)
	echo "     [ UGEEK WORKSHOP ]"
	echo "http://ugeek.aliexpress.com"
	echo "http://ukonline2000.taobao.com"
	exit 1
	;;
esac
done
