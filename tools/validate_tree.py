#!/usr/bin/env python3
"""Check the publishable device tree without needing any stock binary."""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
REQUIRED = (
    "Android.mk", "AndroidProducts.mk", "BoardConfig.mk", "device.mk",
    "omni_szj202.mk", "recovery.fstab", "vendorsetup.sh",
    ".gitignore", ".gitattributes",
    ".github/workflows/build.yml",
)
ALLOWED_SUFFIXES = {".mk", ".md", ".txt", ".sh", ".py", ".yml", ".yaml", ".rc", ".xml", ".fstab"}
FORBIDDEN_COMPONENTS = {"userdata", "persist", "modemst1", "modemst2", "fsg", "nvram", "nvdata", "magisk"}
MAC = re.compile(r"\b(?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2}\b", re.I)
IMEI = re.compile(r"(?<!\d)\d{15}(?!\d)")


def main() -> int:
    problems = []
    for name in REQUIRED:
        if not (ROOT / name).is_file():
            problems.append(f"missing required file: {name}")

    for path in ROOT.rglob("*"):
        if not path.is_file() or ".git" in path.parts or "__pycache__" in path.parts:
            continue
        relative = path.relative_to(ROOT).as_posix()
        if relative.startswith("prebuilt/"):
            continue
        if path.suffix.lower() not in ALLOWED_SUFFIXES and path.name not in {".gitignore", ".gitattributes"}:
            problems.append(f"unexpected non-source file: {relative}")
            continue
        content = path.read_text(encoding="utf-8")
        if MAC.search(content):
            problems.append(f"MAC-like identifier in {relative}")
        if IMEI.search(content):
            problems.append(f"15-digit identifier in {relative}")

    if problems:
        print("Publication check failed:", file=sys.stderr)
        for problem in problems:
            print(f"- {problem}", file=sys.stderr)
        return 1
    print("Publication check passed: no raw/binary files or identifier patterns")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
