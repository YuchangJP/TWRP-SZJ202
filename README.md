# TWRP-SZJ202

TWRP 9.0 (Android 9 based) device tree and GitHub Actions build environment for
the **KYOCERA SZJ-JS202** (JUSTSYSTEMS brand, codename `szj202`).

This repository is modelled on `Lineage14.1-KC-T301DT` (the sibling SZJ201
project) and keeps the same conventions:

* `main` carries only the build environment (`docs/`, `tools/`, the workflow).
* The device tree lives on the **`twrp-9.0`** branch and is consumed through the
  TWRP minimal manifest with a local manifest that maps it to
  `device/kyocera/szj202`.
* No raw firmware, proprietary blobs or device identifiers are committed. The
  one binary the build needs, the stock kernel, is delivered as a release asset.

## Device

| Item | Value |
| --- | --- |
| Marketing model | SZJ-JS202 |
| Brand / manufacturer | JUSTSYSTEMS / KYOCERA |
| Codename | `szj202` |
| SoC | Qualcomm MSM8937 (kernel identifies as msm8940) |
| CPU | 8x ARM Cortex-A53 (arm64, armv8-a) |
| Android | 9 (Pie), security patch 2021-10-01 |
| Build | `JUSTSYSTEMS/SZJ202/SZJ202:9/1.110JS.0151.a/1.110JS.0151.a:user/release-keys` |
| Kernel | Linux 4.9.112-perf (arm64, GCC 4.9.x) |
| Display | 800 x 1280, density 160 (panel "kc boe ilitek wxga") |
| Recovery | dedicated partition, non-A/B, 64 MiB |

See [docs/DEVICE.md](docs/DEVICE.md) for the full analysis and
[docs/BUILD_STATUS.md](docs/BUILD_STATUS.md) for build progress.

## Kernel strategy

TWRP reuses the **stock kernel** (`Image.gz`, extracted verbatim from the stock
`boot` partition). Keeping the OEM kernel guarantees the touch panel, display,
storage and RTC drivers used by recovery are the exact ones the device shipped
with. The device tree is not appended to the kernel; the bootloader applies the
matching FDT from the separate `dtbo` partition, so `recovery.img` contains only
kernel + TWRP ramdisk.

`Image.gz` is published as a release asset (SHA-256 recorded in the workflow)
because binaries are intentionally kept out of git. The GPL kernel source for
build `1.110JS.0151.a` is available from the OEM source package
(`kernel_SZJ-JS202_1.110JS.0151.a.tar.gz`, `kernel/msm-4.9`).

## Building

Dispatch the **TWRP 9.0 SZJ202 build** workflow from the `twrp-9.0` branch:

1. Actions -> *TWRP 9.0 SZJ202 build* -> *Run workflow*.
2. Branch: `twrp-9.0`.
3. `stage`: pick how far to build (`validate`, `sync`, `recoveryimage`).
4. `kernel_repository` / `kernel_ref`: leave empty to use the prebuilt stock
   kernel from the release asset, or point at a kernel source repository to
   build from source instead.

The finished `recovery.img` is uploaded as a workflow artifact.

## Latest build

| | |
| --- | --- |
| Run | [36749009540](https://github.com/YuchangJP/TWRP-SZJ202/actions/runs/36749009540) (stage `recoveryimage`, 18m7s, success) |
| Image | `recovery.img`, 31,606,784 bytes, SHA-256 `e47193e95f0cb42120e06bf6341ed341eea38c93234d642b813da37a8787bd91` |
| Release | [twrp-9.0-szj202-r36749009540](https://github.com/YuchangJP/TWRP-SZJ202/releases/tag/twrp-9.0-szj202-r36749009540) |

This build adds the USB init scripts the device needs, so ADB works; see the
"Recovery boots, but no ADB" section of [docs/BUILD_STATUS.md](docs/BUILD_STATUS.md)
for the diagnosis. Build progress and every CI iteration are recorded there too.

## Flashing (manual, device owner's responsibility)

```
fastboot flash recovery recovery.img
```

The bootloader must be unlocked and Android Verified Boot must tolerate the
unsigned image (the stock `vbmeta` verifies `boot`/`recovery`). This repository
never flashes or reboots a device by itself.

## Layout

```
main branch          twrp-9.0 branch (device/kyocera/szj202)
.github/workflows/   Android.mk
docs/                AndroidProducts.mk
tools/               BoardConfig.mk
                     device.mk
                     omni_szj202.mk
                     recovery.fstab
                     vendorsetup.sh
                     prebuilt/            (kernel supplied by CI)
```
