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

# The QTI Keymaster 3.0 and Gatekeeper passthrough implementations abort as soon
# as they are opened in recovery ("get_version status failed" out of
# KeymasterUtils - the TA they look for is not on this device). TWRP's Keymaster
# wrapper probes every HAL version, so simply having those files on disk takes
# the recovery process down with it. Shadow them with an empty file: the
# passthrough fetch then finds nothing and the probe is skipped instead.
#
# The source has to be a regular file. toybox mount treats an argument like
# /dev/null as an image and fails with "losetup failed", which is why this is
# not a /dev/null bind.
SHADOW=/tmp/hal-shadow
: > "$SHADOW"
for f in \
    /vendor/lib64/hw/android.hardware.keymaster@3.0-impl-qti.so \
    /vendor/lib64/hw/android.hardware.gatekeeper@1.0-impl-qti.so ; do
    [ -f "$f" ] && mount -o bind "$SHADOW" "$f" 2>/dev/null
done
exit 0
