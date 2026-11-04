# blight 👻

> **blight** is a collection of system cleaning utilities for Arch Linux administrators, designed to remediate the creep of orphaned packages, users, groups, files, and locales that accumulate during the lifecycle of a well-used system.

[![License: GPL3](https://img.shields.io/badge/License-GPL%203-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.html)
[![Arch Linux](https://img.shields.io/badge/Platform-Arch%20Linux-1793d1.svg)](https://archlinux.org/)
[![Language: Bash](https://img.shields.io/badge/Language-Bash-green.svg)](#)

## Requirements

- **Bash** 4.0 or later
- **Arch Linux** or Arch-based distribution

## Utilities

### blight-users

**Exorcise the phantom users haunting your system.**

Identifies and removes orphaned system users left behind by uninstalled packages, with interactive prompts and automatic group cleanup.

```bash
sudo blight-users.sh [--dry-run]
```
## Planned Utilities

- **blight-groups** — Banish orphaned groups from the digital grave.
- **blight-files** — Lay to rest the spectral remnants of uninstalled packages.
- **blight-locales** — Expel the ghost translations lurking in your filesystem.

## Contributing

Contributions are welcome. Please ensure scripts are tested on Arch Linux and maintain compatibility with Bash 4.0+. Open an issue or pull request with your improvements.

## License

This project is licensed under the **GNU General Public License v3** (GPL-3.0). See the [LICENSE](LICENSE) file for details.
