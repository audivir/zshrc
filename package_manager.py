from __future__ import annotations

import os
import sys
from pathlib import Path
import platform
import subprocess
from typing import Literal, TYPE_CHECKING
from simple_term_menu import TerminalMenu

if TYPE_CHECKING:
  from typing import TypeAlias

PACKAGES = Path(__file__).parent / "packages"

ManagerT: TypeAlias = Literal["brew", "apt", "manual"]

def create_menu(*options: ManagerT) -> ManagerT | None:
    """Create a terminal menu and return the choice or None if cancelled."""
    terminal_menu = TerminalMenu(options)
    choice_ix = terminal_menu.show()
    if choice_ix is None:
        return None
    return options[choice_ix]

def package_manager(manual_pkg: str, brew_pkg: str, apt_pkg: str) -> None:
    """Install a package over a user-selected installation way."""
    if not manual_pkg:
        raise ValueError("No package name provided")
    manual_script = PACKAGES / f"{manual_pkg}.sh"
    if not manual_script.exists():
        raise ValueError(f"Script to install {manual_pkg} does not exist: {manual_script}")

    options: list[str] = []
    psys = platform.system()
    if psys == "Darwin":
        if brew_pkg:
            options.append("brew")
    elif psys == "Linux":
        if apt_pkg:
            options.append("apt")
    else:
        raise ValueError(f"Unsupported OS: {psys}")
    options.append("manual")

    print(f"Install {manual_pkg} via:")
    choice = create_menu(*options)
    if not choice:
        raise ValueError("Install choice cancelled")

    env = os.environ.copy()
    postinstall_script: Path | None = None
    if choice == "manual":
        subprocess.check_call([manual_script])
    elif choice == "brew":
        env["NONINTERACTIVE"] = "1"
        subprocess.check_call(["brew", "install", brew_pkg], env=env)
        postinstall_script = PACKAGES / "brew" / f"{brew_pkg}.sh"
    elif choice == "apt":
        env["DEBIAN_FRONTEND"] = "noninteractive"
        subprocess.check_call(["sudo", "apt-get", "install", "--no-install-recommends", "--yes", apt_pkg], env=env)
        postinstall_script = PACKAGES / "apt" / f"{apt_pkg}.sh"
    else:
        raise ValueError(f"Unexpected install choice: {choice}")

    if postinstall_script and postinstall_script.exists():
        subprocess.check_call([postinstall_script])

def main() -> None:
    """Main entrypoint for the CLI."""
    # TODO(tihoph): use ArgumentParser?
    if len(sys.argv) < 4:
        raise ValueError("Not enough arguments")
    manual_pkg = sys.argv[1]
    brew_pkg = sys.argv[2]
    apt_pkg = sys.argv[3]
    package_manager(manual_pkg, brew_pkg, apt_pkg)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"{e}", file=sys.stderr)
        raise SystemExit(1) from e
