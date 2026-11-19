#!/usr/bin/env python3
"""Check that the installed runtime carries every file the release recipe names."""

import argparse
import importlib.util
from pathlib import Path
import sys


def main():
    parser = argparse.ArgumentParser(description="Check the installed Raven runtime file set")
    parser.add_argument("--build", type=Path, required=True, help="configured CMake build directory")
    parser.add_argument("--out", type=Path, required=True, help="installed package output")
    parser.add_argument("--source", type=Path, required=True, help="Raven source tree")
    parser.add_argument("--manifest", type=Path, help="write the expected relative names here")
    args = parser.parse_args()

    recipe = args.source / "scripts/package-native.py"
    specification = importlib.util.spec_from_file_location("package_native", recipe)
    module = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(module)

    root = args.out / "libexec/raven"
    expected = module.runtime_paths(args.build.resolve())
    missing = sorted(name for name in expected if not (root / name).exists())
    if missing:
        print("the installed runtime is missing files the release recipe names:", file=sys.stderr)
        for name in missing:
            print(f"  {name}", file=sys.stderr)
        return 1
    if args.manifest:
        args.manifest.write_text("".join(f"{name}\n" for name in sorted(expected)))
    print(f"runtime contract: {len(expected)} files present")
    return 0


if __name__ == "__main__":
    sys.exit(main())
