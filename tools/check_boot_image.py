#!/usr/bin/env python3
"""Print the structure of an Android boot image offline.

Used by CI to record the generated recovery.img header and payloads without
copying the image anywhere. Handles header versions 0 and 1.
"""

import argparse
import gzip
import struct
import sys


def align(value: int, page: int) -> int:
    return (value + page - 1) // page * page


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("image")
    args = parser.parse_args()

    data = open(args.image, "rb").read()
    if data[:8] != b"ANDROID!":
        print("not an Android boot image", file=sys.stderr)
        return 1
    (kernel_size, kernel_addr, ramdisk_size, ramdisk_addr,
     second_size, second_addr, tags_addr, page_size,
     header_version, os_version) = struct.unpack("<IIIIIIIIII", data[8:48])
    cmdline = data[64:576].split(b"\x00")[0]

    print(f"size           : {len(data)} bytes")
    print(f"header_version : {header_version}")
    print(f"os_version     : 0x{os_version:08x}  "
          f"({os_version >> 25}.{(os_version >> 18) & 0x7f}.{(os_version >> 11) & 0x7f}, "
          f"patch {2000 + ((os_version & 0x7ff) >> 4)}-{os_version & 0xf:02d})")
    print(f"page_size      : {page_size}")
    print(f"kernel         : {kernel_size} bytes @ 0x{kernel_addr:08x}")
    print(f"ramdisk        : {ramdisk_size} bytes @ 0x{ramdisk_addr:08x}")
    print(f"second         : {second_size} bytes @ 0x{second_addr:08x}")
    print(f"tags_addr      : 0x{tags_addr:08x}")
    print(f"cmdline        : {cmdline.decode('latin1')}")

    koff = page_size
    kernel = data[koff:koff + kernel_size]
    if kernel[:2] == b"\x1f\x8b":
        kernel_kind = "gzip Image.gz"
    elif kernel[:4] == b"ARMd":
        kernel_kind = "uncompressed Image"
    else:
        kernel_kind = "unknown"
    print(f"kernel magic   : {kernel[:8].hex()} ({kernel_kind})")

    roff = align(page_size + kernel_size, page_size)
    ramdisk = data[roff:roff + ramdisk_size]
    if ramdisk[:2] == b"\x1f\x8b":
        try:
            n = len(gzip.decompress(ramdisk))
            print(f"ramdisk        : gzip cpio, {n} bytes uncompressed")
        except Exception as exc:  # pragma: no cover - diagnostic only
            print(f"ramdisk        : gzip cpio (decompress failed: {exc})")
    else:
        print(f"ramdisk magic  : {ramdisk[:4].hex()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
