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

## Milestones

| Milestone | Status | Evidence / next gate |
| --- | --- | --- |
| Device identity resolved | Yes | `system`/`vendor` build props. |
| Partition table known | Yes | GPT in `mmcblk0`. |
| Stock recovery fstab extracted | Yes | `recovery` ramdisk. |
| Device tree authored | Yes | `twrp-9.0` branch. |
| Prebuilt kernel published | Yes | Release `prebuilt-kernel-1.110JS.0151.a`. |
| `recovery.img` build | Yes, structural | Run 36737914000 produced a 31,604,736-byte `recovery.img`. |
| Device boot / display / touch | Untested | Requires flashing; not performed here. |

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
