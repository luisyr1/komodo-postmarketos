#!/bin/sh
# Initramfs hook of device-google-komodo (installed by devicepkg_package as
# /usr/share/mkinitfs/hooks/00-device-google-komodo.sh). init_2nd.sh runs it
# from run_hooks /hooks: after udev, the USB gadget and unudhcpd are up, and
# BEFORE mount_subpartitions() looks for the pmOS image inside userdata.

# 1. UFS read-only guard. The udev rule covers devices that show up later.
if [ -x /usr/libexec/google-komodo-ufs-ro ]; then
	/usr/libexec/google-komodo-ufs-ro --all ||
		echo "google-komodo: WARNING: UFS read-only guard incomplete" > /dev/kmsg
else
	echo "google-komodo: WARNING: /usr/libexec/google-komodo-ufs-ro missing" > /dev/kmsg
fi

# 2. Serial console over USB: add a CDC ACM function (ttyGS0) to the NCM
# gadget the initramfs created, so a getty can run on it (in the debug shell
# here, serial-getty@ttyGS0 in the installed system). The gadget is unbound
# for a moment; usb0 and its address stay.
G=/sys/kernel/config/usb_gadget/g1
if [ -d "$G/configs/c.1" ] && [ ! -e "$G/functions/acm.usb0" ]; then
	udc=$(cat "$G/UDC" 2>/dev/null)
	[ -n "$udc" ] && echo "" > "$G/UDC"
	if mkdir "$G/functions/acm.usb0" 2>/dev/null; then
		ln -s "$G/functions/acm.usb0" "$G/configs/c.1/" ||
			echo "google-komodo: could not link acm.usb0" > /dev/kmsg
	else
		echo "google-komodo: could not create acm.usb0" > /dev/kmsg
	fi
	[ -n "$udc" ] && echo "$udc" > "$G/UDC"
elif [ ! -d "$G/configs/c.1" ]; then
	echo "google-komodo: no USB gadget g1 (UDC late?), no ACM console" > /dev/kmsg
fi
exit 0
