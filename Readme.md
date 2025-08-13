# **Volund** - The Forge for Modular and Containerized Workspace Tool

Volund is an open-source utility designed to provide a **modular, containerized workspace** environment for pentesting, hacking, DevSecOps, and more. Built with **flexibility and reproducibility** in mind, it leverages Podman (should be docker compatible), WSL, and Ansible for seamless setup and configuration on Windows systems.

Volund is inspired by the legendary Norse blacksmith Völundr—a master artisan whose forge was said to craft weapons and artifacts of divine power

Let Volund be your forge: produce, shape, and reuse your customized working environments with the freedom, ingenuity, and mastery worthy of the mythic smith who inspired its name.

## Features

- **Create containers** based on popular distributions: Debian, ArchLinux, Fedora, BlackArch, Parrot OS, Kali, etc.
- **Customize containers** with Ansible: install tools and tailor configurations with ease.
- **Build persistent volumes** (data or application) that can be reused/shared across containers.
- **Mount workspaces** on the host for hassle-free file exchange.
- **Minimal installation:** Requires only WSL (Windows Subsystem for Linux) and Podman (user mode), and should be compatible with docker.
- **Suitable for Windows environments,** developed fully in PowerShell.

## Typical Use Cases

- **Pentesting and cybersecurity labs**
- **DevSecOps development or testing environments**
- **Customizable developer workspaces**
- **Educational labs and sandboxes**

## Quick Start

### Prerequisites

- Windows with WSL installed (installation requires administrative rights)
- Podman installed in user mode (podman extracted from zip file is OK)

### Installation

1. Clone the repository or download the ZIP:
    ```powershell
    git clone https://github.com/RunarSmith/volund.git
    ```
    or download the project as a ZIP and extract it.

2. Create a custom alias for convenience:
    ```powershell
    Set-Alias -Value <absolute path to volund.ps1> -Name vol
    ```
    *Add this line to your `profile.ps1` for persistent access.*

### Primary Commands

| Command | Description |
|---|---|
| `vol init` | Launch Podman. |
| `vol info` | Show images, containers and volumes. |
| `vol build -Image <custom image name> -Distribution <source distribution>` | Build a container image based on a chosen distribution. |
| `vol start -Container <custom container name> -Image <custom image name>` | Create and start a new container from an image. |
| `vol start -Container <custom container name> -Image <custom image name> -WithGui` | Create and configure a container to allow GUI applications. |
| `vol start -Container <custom container name>` | Start an existing container or open a session on a running one. |
| `vol newv -Volume <custom volume name>` | Create a new custom volume. |
| `vol start -Container <custom container name> -Image <custom image name> -Volume <custom volume name>` | Create and start a new container from an image and mount a custom volume. |

### Volumes & Workspaces

- Data volumes can be created and **shared among multiple containers**.
- Every container has a `workspace` folder mounted from the host, allowing for **easy file exchange** and persistence.

## Architecture

- **Container Engine:** Podman (runs rootless under user context), should be compatible with docker
- **Configuration Management:** Ansible for reliable, reproducible provisioning
- **Host System:** Windows (via PowerShell scripting), leveraging WSL

## Limitations & known issues

- **Windows folder sharing:** When host folders are mounted into containers via Podman/Docker, the underlying filesystems differ (NTFS vs. Linux). As a result, running `chown` or `chmod` inside the container on these volumes may fail or have no effect. This is a known limitation of cross-platform volume, and impact volumes `workspace`, `resources`, and `my-resources`.

## Contributing

Contributions, issues, and feature requests are welcome! Please open an issue or submit a pull request on GitHub.

## License

MIT License. See [LICENSE](LICENSE) for more information.

*Volund brings reproducible, isolated, and versatile workspaces to your Windows environment with minimal setup and maximum scalability.*