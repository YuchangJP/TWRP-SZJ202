# SZJ202 device analysis

All values below come from the read-only firmware dump (`by-name/` partitions
plus the full `mmcblk0` image). No value is guessed.

## Identity

| Property | Value | Source |
| --- | --- | --- |
| `ro.product.model` | SZJ-JS202 | `system/build.prop` |
| `ro.product.device` / `ro.product.name` | SZJ202 | `system/build.prop` |
| `ro.product.brand` | JUSTSYSTEMS | `system/build.prop` |
| `ro.product.manufacturer` | KYOCERA | `vendor/build.prop` |
| `ro.board.platform` | msm8937 | `vendor/build.prop` |
| `ro.build.flavor` | msm8937_64-user | `system/build.prop` |
| `ro.build.version.release` | 9 | `system/build.prop` |
| `ro.build.version.security_patch` | 2021-10-01 | `system/build.prop` |
| `ro.build.date` | Thu Sep 22 00:44:36 JST 2022 | `system/build.prop` |
| `ro.build.fingerprint` | JUSTSYSTEMS/SZJ202/SZJ202:9/1.110JS.0151.a/1.110JS.0151.a:user/release-keys | `vendor/build.prop` |
| `ro.build.system_root_image` | true | `system/build.prop` |
| `ro.sf.lcd_density` | 160 | `vendor/build.prop` |

## Kernel

`Linux version 4.9.112-perf (build@AMATERAS) (gcc version 4.9.x 20150123
(prerelease)) #1 SMP PREEMPT Thu Sep 22 00:52:58 JST 2022`.

* arm64, `CONFIG_LOCALVERSION "-perf"`.
* The stock kernel source package is `kernel_SZJ-JS202_1.110JS.0151.a.tar.gz`;
  the source root is `kernel/msm-4.9` and includes
  `arch/arm64/configs/msm8937-perf_defconfig`, `msm8937_defconfig` and
  `kc_defconfig`, plus APQ8017 / MSM8937 / MSM8940 device trees.

## Boot image format

Both `boot` and `recovery` are Android boot images, header **version 1**:

| Field | Value |
| --- | --- |
| page size | 2048 |
| kernel addr | 0x80008000 |
| ramdisk addr | 0x81000000 |
| tags addr | 0x80000100 |
| kernel | gzip `Image.gz`, 14,334,297 bytes |
| ramdisk (`recovery`) | gzip cpio, 5,591,544 bytes (boot has none) |
| os_version | 0x1200015a (Android 9, patch 2021-10-01) |

The kernel carries **no appended FDT**. Device trees live in the separate
`dtbo` partition as an Android DT table (magic `0xd7b7ab1e`) with 24 entries.
Every entry is packed at 2048-byte pages. Panels described in it:

* `icn9706 720 1440p video mode dsi panel` (720x1440) — 21 entries
* `hx83102 video mode dsi panel` (720x1440) — 1 entry
* `kc boe ilitek wxga video mode dsi panel` (800x1280) — 2 entries

`ro.sf.lcd_density=160` and the Kyocera-specific 800x1280 panel match the
sibling SZJ201 tablet, so the TWRP theme targets 800x1280 portrait.

## Stock kernel cmdline (copied verbatim into the boot header)

```
console=ttyMSM0,115200,n8 androidboot.console=ttyMSM0 androidboot.hardware=qcom
msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1
androidboot.bootdevice=7824900.sdhci earlycon=msm_serial_dm,0x78B0000
firmware_class.path=/vendor/firmware_mnt/image androidboot.usbconfigfs=true
loop.max_part=7 buildvariant=user
```

`buildvariant=user` is added by the stock build; the TWRP build appends its own
variant, so the header is not expected to be byte-identical.

## Partition table

Parsed from the GPT in the full `mmcblk0` dump (512-byte logical sectors).

| # | name | size (bytes) | size |
| --- | --- | --- | --- |
| 1 | modem | 88080384 | 84 MiB |
| 2/3 | sbl1 / sbl1bak | 524288 | 512 KiB |
| 4/5 | rpm / rpmbak | 524288 | 512 KiB |
| 6/7 | tz / tzbak | 2097152 | 2 MiB |
| 8 | reserve1 | 6291456 | 6 MiB |
| 9 | cdt | 8192 | 8 KiB |
| 10/11 | bfss1 / bfss2 | 4194304 / 8388608 | 4 / 8 MiB |
| 12/13 | modemst1 / modemst2 | 1572864 | 1.5 MiB |
| 14 | dnand | 8388608 | 8 MiB |
| 15 | sysprop | 8388608 | 8 MiB |
| 16 | persist | 33554432 | 32 MiB |
| 17 | logwork | 62914560 | 60 MiB |
| 18 | log | 20971520 | 20 MiB |
| 19 | btwk | 16777216 | 16 MiB |
| 20 | chkcode | 524288 | 512 KiB |
| 21 | mglog | 1048576 | 1 MiB |
| 22/23 | sum_ro / sum_rw | 524288 | 512 KiB |
| 24 | reserve2 | 8388608 | 8 MiB |
| 25 | fsc | 8192 | 8 KiB |
| 26 | ssd | 8192 | 8 KiB |
| 27 | misc | 1048576 | 1 MiB |
| 28 | keystore | 524288 | 512 KiB |
| 29/30 | config / limits | 32768 | 32 KiB |
| 31 | mota | 524288 | 512 KiB |
| 32 | dip | 1048576 | 1 MiB |
| 33 | syscfg | 524288 | 512 KiB |
| 34 | mcfg | 4194304 | 4 MiB |
| 35/36 | apdp / msadp | 262144 | 256 KiB |
| 37 | dpo | 8192 | 8 KiB |
| 38 | logdump | 67108864 | 64 MiB |
| 39 | reserve3 | 6717440 | ~6.4 MiB |
| 40 | DDR | 32768 | 32 KiB |
| 41 | fsg | 1572864 | 1.5 MiB |
| 42 | sec | 16384 | 16 KiB |
| 43 | devinfo | 8388608 | 8 MiB |
| 44/45 | devcfg / devcfgbak | 262144 | 256 KiB |
| 46 | dsp | 16777216 | 16 MiB |
| 47/48 | aboot / abootbak | 1048576 | 1 MiB |
| 49/50 | dtbo / dtbobak | 8388608 | 8 MiB |
| 51/52 | vbmeta / vbmetabak | 65536 | 64 KiB |
| 53 | **boot** | 67108864 | 64 MiB |
| 54 | **recovery** | 67108864 | 64 MiB |
| 55-60 | cmnlib / cmnlib64 / keymaster (+ bak) | 1048576 | 1 MiB |
| 61 | reserve4 | 6111232 | ~5.8 MiB |
| 62 | mdtp | 33554432 | 32 MiB |
| 63 | splash | 33554432 | 32 MiB |
| 64 | system | 2709520384 | 2584 MiB |
| 65 | vendor | 671088640 | 640 MiB |
| 66 | cache | 838860800 | 800 MiB |
| 67 | userdata | 10783555584 | ~10050 MiB |
| 69 | reserve5 | 2080256 | ~2 MiB |

The stock `recovery.fstab` also references a `/dev/block/bootdevice/by-name/userdata_zemi`
partition. **No such partition exists in this unit's GPT**, so it is omitted
from the TWRP fstab; it belongs to another SKU sharing the same recovery image.

## Boot chain

* Non-A/B, dedicated `recovery` partition.
* `boot`/`recovery`/`system`/`vendor` are covered by the stock `vbmeta`
  (`wait,avb` in the stock fstab). Flashing an unsigned recovery therefore
  requires an unlocked bootloader, exactly as with the SZJ201 project.
