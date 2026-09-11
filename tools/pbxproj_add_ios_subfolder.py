#!/usr/bin/env python3
"""
Add ONE PBXFileSystemSynchronizedRootGroup entry for the given subfolder,
wired into both bunny macOS and bunny tvOS targets.

Idempotent: if the subfolder is already in the project, exits without
changes.

Usage: python3 tools/pbxproj_add_ios_subfolder.py "bunny iOS/Scenes"
       (run from repo root)

UUIDs are deterministic from the subfolder name (last 4 hex chars of
the path encoded). Inspect pbxproj before/after via `git diff` to
review the additions.
"""

import hashlib
import sys
from pathlib import Path

PBXPROJ = Path("bunny.xcodeproj/project.pbxproj")
TARGET_UUIDS = {
    "macOS": "3CBEC83F3051B47F00EA41A0 /* bunny macOS */",
    "tvOS":  "3CBEC82F3051B47F00EA41A0 /* bunny tvOS */",
}

CHILDREN_ANCHOR = (
    "\t\t\t\t3CBEC8413051B47F00EA41A0 /* bunny macOS */,\n"
)


def stable_uuid(seed: str) -> str:
    """Return a 24-char uppercase hex UUID derived from the seed."""
    digest = hashlib.sha1(seed.encode("utf-8")).hexdigest().upper()
    return digest[:24]


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: pbxproj_add_ios_subfolder.py <subfolder-path>",
              file=sys.stderr)
        return 2
    subfolder = sys.argv[1]
    if not subfolder.startswith("bunny iOS/"):
        print(f"subfolder must start with 'bunny iOS/' (got {subfolder!r})",
              file=sys.stderr)
        return 2

    sub_uuid   = stable_uuid(f"sub:{subfolder}")
    exc_mac_uuid = stable_uuid(f"exc:{subfolder}:macOS")
    exc_tv_uuid  = stable_uuid(f"exc:{subfolder}:tvOS")

    text = PBXPROJ.read_text(encoding="utf-8")

    if sub_uuid in text:
        print(f"{subfolder} already in pbxproj")
        return 0

    if CHILDREN_ANCHOR not in text:
        print(f"FAIL: children anchor not found", file=sys.stderr)
        return 1

    # 1. New PBXFileSystemSynchronizedRootGroup entry
    root_block = (
        f"\t\t{sub_uuid} /* {subfolder} */ = {{\n"
        f"\t\t\tisa = PBXFileSystemSynchronizedRootGroup;\n"
        f"\t\t\texceptions = (\n"
        f"\t\t\t\t{exc_mac_uuid} /* Exceptions for \"{subfolder}\" folder in \"bunny macOS\" target */,\n"
        f"\t\t\t\t{exc_tv_uuid} /* Exceptions for \"{subfolder}\" folder in \"bunny tvOS\" target */,\n"
        f"\t\t\t);\n"
        f"\t\t\tpath = \"{subfolder}\";\n"
        f"\t\t\tsourceTree = \"<group>\";\n"
        f"\t\t}};\n"
    )
    insert_after = "/* Begin PBXFileSystemSynchronizedRootGroup section */\n"
    text = text.replace(insert_after, insert_after + root_block, 1)

    # 2. New PBXFileSystemSynchronizedBuildFileExceptionSet entries
    exc_blocks = []
    for tname, ex_uuid in (("macOS", exc_mac_uuid), ("tvOS", exc_tv_uuid)):
        tid = TARGET_UUIDS[tname]
        exc_blocks.append(
            f"\t\t{ex_uuid} /* Exceptions for \"{subfolder}\" folder in "
            f"\"bunny {tname}\" target */ = {{\n"
            f"\t\t\tisa = PBXFileSystemSynchronizedBuildFileExceptionSet;\n"
            f"\t\t\tmembershipExceptions = (\n"
            f"\t\t\t);\n"
            f"\t\t\ttarget = {tid};\n"
            f"\t\t}};\n"
        )
    insert_before = "/* End PBXFileSystemSynchronizedBuildFileExceptionSet section */"
    text = text.replace(insert_before, "".join(exc_blocks) + "\t" + insert_before, 1)

    # 3. Append new child to main project PBXGroup children array.
    new_child = f"\t\t\t\t{sub_uuid} /* {subfolder} */,\n"
    text = text.replace(CHILDREN_ANCHOR, CHILDREN_ANCHOR + new_child, 1)

    PBXPROJ.write_text(text, encoding="utf-8")
    print(f"Added {subfolder}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
