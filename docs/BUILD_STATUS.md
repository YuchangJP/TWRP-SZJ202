# Build status

Date: 2026-09-30. Firmware dump analysed read-only; no device was flashed,
rebooted, or otherwise modified.

## Device analysis

All values in [DEVICE.md](DEVICE.md) were taken from the dump: identity from
`system`/`vendor` build props, kernel version from the decompressed stock
kernel, boot header fields from the stock `boot`/`recovery` images, the DT table
from `dtbo`, and the partition table from the GPT inside the full `mmcblk0`
image. The stock `recovery.fstab` and its ramdisk were extracted from the stock
`recovery` image.

## Relationship to SZJ201

The SZJ201 bring-up (`Lineage14.1-KC-T301DT`) established the conventions this
repository reuses: build-environment default branch, device tree on a dedicated
branch, `repo` with a local manifest, a publication validator, staged CI, and no
binaries in git. The two devices differ in SoC (SZJ201 = MSM8916 / kernel
3.10.49; SZJ202 = MSM8937 / kernel 4.9.112) and in Android version (7.1 vs 9).

## Kernel strategy

TWRP reuses the stock kernel. `Image.gz` (14,334,297 bytes, SHA-256
`23bc66781c6579bb68d2736c7bcf6a8a946cbe6a0960d7c33701e2db19264453`) is extracted
from the stock `boot` partition and published as the release asset
`prebuilt-kernel-1.110JS.0151.a`. The workflow downloads it and verifies the
hash before the build. The matching GPL kernel source is the OEM package
`kernel_SZJ-JS202_1.110JS.0151.a.tar.gz` (source root `kernel/msm-4.9`).

## CI run log

* [Run 36735449778](https://github.com/YuchangJP/TWRP-SZJ202/actions/runs/36735449778)
  (stage `recoveryimage`) passed checkout, validation, input checks and the
  runner cleanup, then stopped while configuring swap: the hosted runner
  already had an active `/swapfile`, so `fallocate` on that path returned
  `Text file busy` (exit 1 after 44s). The step now reuses an existing swap or
  creates one under `$RUNNER_TEMP` instead of hard-coding `/swapfile`.
* [Run 36735859075](https://github.com/YuchangJP/TWRP-SZJ202/actions/runs/36735859075)
  (stage `recoveryimage`) passed swap, dependencies, Java 8, `repo init`, the
  full `twrp-9.0` sync, and kernel provisioning (release asset downloaded with
  the recorded SHA-256 verified). The build then failed after the Soong
  configuration phase:

  ```
  prebuilts/clang/host/linux-x86/clang-4691093/bin/clang.real:
    error while loading shared libraries: libtinfo.so.5: cannot open shared object file
  ```

  The Android 9 prebuilt clang links against `libtinfo.so.5`, which Ubuntu
  22.04 does not ship by default. `libtinfo5`/`libncurses5` are now installed
  with the other build dependencies.
* [Run 36737914000](https://github.com/YuchangJP/TWRP-SZJ202/actions/runs/36737914000)
  (stage `recoveryimage`) **succeeded** in 15m55s and produced `recovery.img`
  (31,604,736 bytes, well below the 64 MiB partition). Structure:

  | Field | Value |
  | --- | --- |
  | header_version | 0 |
  | page_size | 2048 |
  | kernel | gzip `Image.gz`, 14,334,297 bytes @ 0x80008000 (stock size) |
  | ramdisk | 17,266,063 bytes @ 0x81000000 (52,134,400 bytes uncompressed) |
  | cmdline | stock cmdline + `buildvariant=eng` |

  The ramdisk is a complete TWRP rootfs: `sbin/recovery`, 91 files under
  `twres/`, the embedded Python, and `/etc/recovery.fstab` byte-for-byte the
  tree's fstab.

  The `Capture diagnostics` step also exposed a host-Python compatibility bug:
  `tools/check_boot_image.py` used an f-string with a backslash in the
  expression, which Python < 3.12 rejects (`SyntaxError: f-string expression
  part cannot include a backslash`). The step is guarded with `|| true` so the
  job still passed, but the tool is now rewritten to avoid it.
* [Run 36746269355](https://github.com/YuchangJP/TWRP-SZJ202/actions/runs/36746269355)
  (stage `recoveryimage`, first ADB fix) synced and configured Soong, then
  failed at kati's product check:

  ```
  build/make/core/main.mk:137: error: ADDITIONAL_DEFAULT_PROPERTIES must not
  be set before here: ro.adb.secure=0.
  ```

  `ADDITIONAL_DEFAULT_PROPERTIES` may not be set at all before that point, in
  either `BoardConfig.mk` or a product makefile. The property now uses the
  product-scoped variable `PRODUCT_DEFAULT_PROPERTY_OVERRIDES`.
* [Run 36747585990](https://github.com/YuchangJP/TWRP-SZJ202/actions/runs/36747585990)
  (stage `recoveryimage`, second ADB fix) failed identically: moving the line
  to `device.mk` did not help, because product makefiles are parsed *before*
  `main.mk`'s check. Replaced with `PRODUCT_DEFAULT_PROPERTY_OVERRIDES`.
* [Run 36749009540](https://github.com/YuchangJP/TWRP-SZJ202/actions/runs/36749009540)
  (stage `recoveryimage`) succeeded in 18m7s with the USB init scripts:
  `recovery.img` 31,606,784 bytes, `init.recovery.usb.rc` +
  `init.recovery.qcom.rc` packaged, `ro.adb.secure=0`.
* [Run 36754459715](https://github.com/YuchangJP/TWRP-SZJ202/actions/runs/36754459715)
  (stage `recoveryimage`) succeeded in 14m30s with crypto disabled:
  `recovery.img` 30,009,344 bytes. `e4crypt_initialize_global_de` and
  `retrieveAndInstallKey` are absent from `sbin/recovery`, and the `/data` fstab
  entry carries no `encryptable` flag.
* [Run 36758399531](https://github.com/YuchangJP/TWRP-SZJ202/actions/runs/36758399531)
  (stage `recoveryimage`) succeeded in 21m41s with crypto, landscape, USB OTG
  and Japanese: `recovery.img` 31,606,784 bytes. The patch step applied all
  three TWRP patches; `sbin/libe4crypt.so` contains `e4crypt_initialize_global_de`
  and the patched `Created device keyring`, and the ramdisk carries
  `twres/landscape.xml` (no `portrait.xml`) plus `twres/languages/ja.xml`.

## Milestones

| Milestone | Status | Evidence / next gate |
| --- | --- | --- |
| Device identity resolved | Yes | `system`/`vendor` build props. |
| Partition table known | Yes | GPT in `mmcblk0`. |
| Stock recovery fstab extracted | Yes | `recovery` ramdisk. |
| Device tree authored | Yes | `twrp-9.0` branch. |
| Prebuilt kernel published | Yes | Release `prebuilt-kernel-1.110JS.0151.a`. |
| `recovery.img` build | Yes, structural | Run 36737914000 produced a 31,604,736-byte `recovery.img`. |
| Device boot / display | Yes | Flashed and booted on hardware. |
| ADB over USB | **Yes, verified** | See the hardware verification section. |
| Storage / touch / partitions | Yes, verified | Read-only ADB checks; see below. |
| TWRP UI / main menu | Fixed, unverified | Crypto patch applied; run 36758399531. |
| /data (FBE) decryption | Implemented, unverified | Same run; proof requires flashing. |
| Radios (modem/Wi-Fi/BT) | Untested | Requires the user on hardware. |

## Hardware verification (2026-09-30)

The r36749009540 image was flashed and queried over ADB (read-only; nothing was
written, wiped or flashed from the tooling).

| Item | Result |
| --- | --- |
| ADB | `KB18K627078 recovery product:omni_szj202 model:SZJ_JS202 device:szj202`; root shell (`uid=0`, `u:r:su:s0`) |
| TWRP | `3.7.0_9-SZJ202-1` |
| USB | `sys.usb.config=adb`, `sys.usb.configfs=1`, `sys.usb.ffs.ready=1`, UDC bound to `msm_hsusb`; dmesg shows the `sys.usb.ffs.ready=1` action from `/init.recovery.qcom.rc` and `USB_STATE=CONNECTED`/`CONFIGURED` |
| Display | fbdev, `framebuffer: 0 (800 x 1280)`; `portrait_hdpi` theme scaled 0.740741 x 0.666667 |
| Panel | bootloader cmdline `...qcom,mdss_dsi_kc_boe_ilitek_wxga_video...` with `androidboot.dtbo_idx=22` |
| Touch / keys | `goodix-ts` (event2), `gpio-keys` (event5), `qpnp_pon` (event0), `Wacom I2C Digitizer` (event1) |
| `/system` | mounts read-only; dm-verity is active (`root=/dev/dm-0`, `androidboot.veritymode=enforcing`) |
| `/vendor`, `/cache`, `/data`, `/firmware` | all mount; `/data` FBE unwrapped from `/data/unencrypted/key` |
| RTC | corrected from `/persist/time/ats_2` |
| Bootloader | `androidboot.verifiedbootstate=orange` (unlocked) |
| SELinux | permissive (bring-up); all audit denials carry `permissive=1` |

Cosmetic findings, no action taken:

* `I:Unhandled flag: 'nofail'` — TWRP does not recognise the `nofail` flag on the
  `/mnt/vendor/pstore` entry; it is ignored.
* USB mass-storage mode is unavailable (`Lun file
  '/sys/class/android_usb/android0/f_mass_storage/lun0/file' does not exist`),
  because the device is a configfs gadget. ADB is unaffected; UMS would need a
  `mass_storage` function in the gadget.
* dm-verity on `/system` means the stock system cannot be modified in place
  without disabling verity.

## Recovery boots, but no ADB (2026-09-30)

The first flashed image (run 36737914000) booted on hardware but did not appear
over USB. Analysing the built ramdisk showed why:

* TWRP's `init.rc` declares `adbd` as a **disabled** service and comments out
  the `ro.debuggable=1` auto-start. `adbd` is therefore only ever started by
  `init.recovery.usb.rc` through `on property:sys.usb.config=adb`.
* The same `init.rc` imports `/init.recovery.usb.rc` and
  `/init.recovery.${ro.hardware}.rc` (= `init.recovery.qcom.rc`), but the
  ramdisk contained **neither file**.
* `TW_EXCLUDE_DEFAULT_USB_INIT := true` had removed TWRP's
  `init.recovery.usb.rc`, and no device-side `init.recovery.qcom.rc` was ever
  supplied, so nothing configured the USB gadget and nothing ever started
  `adbd`.

TWRP's stock `init.recovery.usb.rc` only speaks the **legacy**
`/sys/class/android_usb/android0` interface, while this device is a **configfs**
gadget (`androidboot.usbconfigfs=true`; the factory recovery builds
`/config/usb_gadget/g1` with `idVendor 0x18d1`, `idProduct 0xd001`, `ffs.adb`
and binds the UDC when `sys.usb.ffs.ready=1`).

Fixes:

* Removed `TW_EXCLUDE_DEFAULT_USB_INIT` so TWRP's `init.recovery.usb.rc` is
  packaged again.
* Added `recovery/root/init.recovery.qcom.rc` (packaged through
  `TARGET_RECOVERY_DEVICE_DIRS`) with the factory configfs gadget setup, the
  `sys.usb.ffs.ready=1` UDC bind, the `/dev/block/bootdevice` symlink and an
  explicit `start adbd` on `on boot`.
* Added `ADDITIONAL_DEFAULT_PROPERTIES += ro.adb.secure=0` so adbd does not
  wait for an authorised key.
* Appended `androidboot.selinux=permissive` to the cmdline for bring-up, so the
  configfs writes from `init` are not blocked before TWRP relaxes policy.

## Recovery hangs on the splash screen (2026-09-30)

With ADB working, the recovery was found not to advance past the TWRP splash.
Diagnosed read-only over ADB on the r36749009540 image:

* `recovery` (pid 344) has a **single thread parked in `futex_wait_queue_me`** —
  a userspace deadlock, not I/O and not CPU spin.
* `/tmp/recovery.log` (3249 bytes, not growing) ends at:

  ```
  I:File Based Encryption is present
  e4crypt_initialize_global_de
  Determining wrapped-key support for /data
  fbe.data.wrappedkey = false
  calling retrieveAndInstallKey
  Key exists, using: /data/unencrypted/key
  ```

* That is `crypto/ext4crypt/Ext4CryptPie.cpp` → `android::vold::retrieveAndInstallKey()`.
  It never returns; `partition.cpp` calls it from the `#ifdef TW_INCLUDE_FBE`
  block (`while (!Decrypt_DE() && --retry_count)`), so the UI thread never
  reaches the main menu.

Cause: `TW_INCLUDE_CRYPTO := true` also force-enables `TW_INCLUDE_FBE` and
`TW_INCLUDE_FBE_METADATA_DECRYPT` (TWRP `Android.mk`), so TWRP tries to unwrap
the FBE key. On this unit `/data/unencrypted/key/` contains:

| file | size |
| --- | --- |
| `encrypted_key` | 92 B |
| `keymaster_key_blob` | 449 B |
| `secdiscardable` | 16384 B |
| `stretching` | 10 B (`nopassword`) |
| `version` | 1 B (`1`) |

`keymaster_key_blob` means the key is wrapped by the device's Keymaster (QSEE)
key, so unwrapping needs the vendor keymaster stack, which this blob-free tree
does not ship. The vendor partition does have it:
`/vendor/lib64/hw/android.hardware.keymaster@3.0-impl-qti.so`,
`libQSEEComAPI.so`, `libkeymasterdeviceutils.so`, `libkeymasterprovision.so`,
`libkeymasterutils.so`, `libqtikeymaster4.so`, `/vendor/bin/qseecomd`,
`/vendor/bin/hw/android.hardware.keymaster@{3.0,4.0}-service-qti`.

Fix: `TW_INCLUDE_CRYPTO := false`, and the `encryptable=footer` flag removed
from the `/data` fstab entry so TWRP mounts /data as a plain ext4 filesystem.

Consequence: TWRP boots, flashes, wipes and backs up, but per-file encrypted
contents stay unreadable. Restoring /data decryption later requires shipping
that Keymaster stack (and running `hwservicemanager`) from a private blob
repository — never this public tree.

## /data decryption, landscape, USB OTG and Japanese (2026-09-30)

The splash hang was finally localised by reading TWRP's source against this
device. TWRP's `crypto/ext4crypt/KeyStorage3.h` and `KeyStorage4.h` define

```cpp
bool usesKeymaster() const { return !token.empty() || secret.empty(); };
```

where AOSP has `!secret.empty()`. With the empty `KeyAuthentication` that
`Decrypt_DE()` passes for the FBE device key, the first term is already true, so
TWRP took the Keymaster path: `KeyStorage4::retrieveKey()` constructs
`android::vold::Keymaster`, which calls
`android::hardware::keymaster::V4_0::IKeymasterDevice::getService()`. Recovery
has no hwservicemanager-registered Keymaster service, so that call blocks in a
futex and the UI never leaves the splash screen.

The device key is **not** Keymaster-wrapped: `/data/unencrypted/key/encrypted_key`
is 92 bytes = 12-byte GCM nonce + 64-byte key + 16-byte tag, and `stretching` is
`nopassword`. The AOSP code path therefore decrypts it without the TEE.

The build now applies three patches to the synced TWRP sources (workflow step
"Patch TWRP FBE sources for this device"); the step fails the build if any patch
does not apply:

| Patch | Why |
| --- | --- |
| `KeyStorage3.h`, `KeyStorage4.h`: `secret.empty()` → `!secret.empty()` | restores the AOSP `usesKeymaster()`; the device key is not Keymaster-backed |
| `KeyUtil.cpp`: create the `e4crypt` keyring when `keyctl_search()` misses | nothing in recovery creates it, so installing any key would fail |
| `partition.cpp`: drop the `fbe.data.wrappedkey=true` retry | that retry needs the Keymaster HAL and would deadlock; a failure now only logs |

Other changes in the same build:

* **Landscape UI** — `TW_THEME := landscape_hdpi` plus `TW_ROTATION := 90`. The
  panel is a native 800x1280 portrait DSI panel, so the drawing is rotated to
  give a 1280x800 UI. `persist.twrp.rotation` overrides the direction at
  runtime, so 270 can be tried without rebuilding.
* **USB OTG / external SD** — the AOSP-style fstab lines carried `wait`, which
  made TWRP block and report a mount error for `/usb_otg` at boot even with
  nothing attached. Both entries now use TWRP's own fstab format (mount point
  first) with `flags=display=...;storage;wipeingui;removable`.
* **Default language** — `TW_DEFAULT_LANGUAGE := ja`; TWRP ships
  `twres/languages/ja.xml`.

## On-device verification of run 36758399531 (2026-09-30)

The image was flashed and queried over ADB. Two of the four changes are proven
working, two are not.

**Working**

* **Japanese default** — `I:LANG: ja`, `/twres/languages/ja.xml` loaded, and the
  UI renders Japanese strings (`MTP 有効`, `内部ストレージ`).
* **Landscape UI** — rotation is applied (`gr_fb_width() > gr_fb_height()`, so
  TWRP selected the landscape layout) and the log shows
  `/twres/landscape.xml` being loaded, with the 1920x1200 theme scaled
  `0.666667x` on both axes to 1280x800.

**Touch is wrong after the rotation.** TWRP rotates the drawing, but the
touchscreen still reports panel-space coordinates; `vk_tp_to_screen()` only
compensates when the device sets the touch flags. For `gr_rotation == 90` the
frame transform is `(u, v) = (w - y - 1, x)`, i.e. `x_ui = v` and `y_ui = h - u`,
which is `RECOVERY_TOUCHSCREEN_SWAP_XY` + `RECOVERY_TOUCHSCREEN_FLIP_Y`. Those
are now set; the mirrored alternative is FLIP_X.

**/data decryption still fails, and the earlier diagnosis was wrong.** The log
shows the FBE initialisation running three times (the retry loop) and ending in

```
Key exists, using: /data/unencrypted/key
Openssl error: 0
```

`Openssl error: 0` comes from `decryptWithoutKeymaster()` — the GCM tag check
fails, so the key derived from the secdiscardable does not match the stored
`encrypted_key`. Together with the 449-byte `keymaster_key_blob` sitting in the
same directory, that means the FBE device key really is **Keymaster-encrypted**,
and TWRP's `usesKeymaster()` with `secret.empty()` (true for an empty
authentication) is intentional, not the typo it was taken for. The patch that
"restored" the AOSP form therefore sends the device key down the wrong path: it
no longer deadlocks (that is why patch 1 is still applied), but it can never
decrypt.

Consequence: `/data` decryption needs the vendor Keymaster stack in recovery —
`/vendor/bin/qseecomd`, `/vendor/bin/hw/android.hardware.keymaster@3.0-service-qti`
(or 4.0), `/vendor/lib64/hw/android.hardware.keymaster@3.0-impl-qti.so`,
`libQSEEComAPI.so`, `libkeymasterdeviceutils.so`, `libkeymasterprovision.so`,
`libkeymasterutils.so`, `libqtikeymaster4.so` — started from
`init.recovery.qcom.rc`, with hwservicemanager (already in the ramdisk). Once
those are present, patch 1 must be dropped so TWRP takes the Keymaster path.

**/external_sd and /usb_otg** now parse as TWRP removable entries (no `wait`),
and only log `I:Unable to mount` with `Actual block device: ''` because no card
or stick is attached; the fstab/parse error is gone.

## Known bring-up risks

* **Boot image header version.** Stock uses header v1; the TWRP build emits v0
  unless told otherwise. The `msm8937` bootloader accepts both, but this is the
  first thing to change if the image is rejected.
* **Android 9 on a modern host.** The build runs on `ubuntu-22.04`. Android 9
  still expects a bare `python` in a few scripts; the workflow installs
  `python2.7` when available and otherwise relies on the manifest's own tools.
* **Display in recovery.** The TWRP build is intentionally blob-free for the
  first pass. If the panel is not brought up through fbdev/DRM, the next step is
  to extract the display/gralloc blobs from `vendor` into a private blob
  repository (never into this public tree).
* **Verified boot.** `boot`/`recovery`/`system`/`vendor` are covered by the
  stock `vbmeta`; flashing requires an unlocked bootloader.
