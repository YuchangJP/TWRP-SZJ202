#!/sbin/sh
# Mounts recovery does not do by itself but the vendor Keymaster stack needs.
# init's `mount` builtin fails for these two partitions, while the shell's
# mount(1) works, so do it from a script invoked with `exec`.

mkdir -p /vendor /firmware
mount -t ext4 -o ro /dev/block/bootdevice/by-name/vendor /vendor 2>/dev/null
mount -t vfat -o ro /dev/block/bootdevice/by-name/modem /firmware 2>/dev/null

# qseecomd reads the Keymaster TA from /firmware/image.
[ -d /firmware/image ] && setprop twrp.dbg.fw 1
[ -d /vendor/bin ] && setprop twrp.dbg.ven 1
exit 0
