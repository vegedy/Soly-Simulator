"""Verify the installed package using isolated Python outside the source tree."""

import sys
import sysconfig
from importlib import import_module
from importlib.metadata import version
from pathlib import Path


def main() -> None:
    if sys.version_info[:3] != (3, 12, 15):
        raise RuntimeError(f"Expected Python 3.12.15, got {sys.version}")
    package = import_module("soly_simulator")
    if package.__file__ is None:
        raise RuntimeError("The installed package has no file")
    package_path = Path(package.__file__).resolve()
    site_packages = Path(sysconfig.get_path("purelib")).resolve()
    if not package_path.is_relative_to(site_packages):
        raise RuntimeError(f"Package imported outside site-packages: {package_path}")
    print(f"Python {sys.version.split()[0]}")
    print(f"soly-simulator {version('soly-simulator')}: {package_path}")


if __name__ == "__main__":
    main()
