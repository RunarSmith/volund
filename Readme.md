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

- **Pentesting, red teaming, cybersecurity labs**
- **DevSecOps development or testing environments**
- **Customizable developer workspaces**
- **Educational labs and sandboxes**

## Quick Start

### Prerequisites

- Windows with WSL installed (installation requires administrative rights)
- Podman installed in user mode (podman extracted from zip file is OK)

**Note**: podman is actually the main driver, but docker should run with little modifications. Adding support for docker is planned in future development

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
    *Optional: Add this line to your `profile.ps1` for persistent access.*

### Primary Commands

| Command | Description |
|---|---|
| `vol setup` | Initialise podman (Create WSL VM and its configuration). |
| `vol info` | Show images, containers and volumes. |
| `vol build -Image <custom image name> -Distribution <source distribution> -Version <image version> -Role <image role>` | Build a container image based on a chosen distribution. |
| `vol start -Container <custom container name> -Image <custom image name>` | Create and start a new container from an image. |
| `vol start -Container <custom container name> -Image <custom image name> -WithGui` | Create and configure a container to allow GUI applications. |
| `vol start -Container <custom container name> -Image <custom image name> -WithGui -VpnConfig <openvpn config.ovn>` | Create and configure a container to allow GUI applications. |
| `vol start -Container <custom container name>` | Start an existing container or open a session on a running one. |
| `vol newv -Volume <custom volume name>` | Create a new custom volume. |
| `vol start -Container <custom container name> -Image <custom image name> -Volume <custom volume name>` | Create and start a new container from an image and mount a custom volume. |

* `-WithGui` : allow gui applications to be displayed
* `-VpnConfig <openvpn config.ovn>` : setup VPN on container startup. provide an openvpn config file.

**Notes:**

* Image Version is a user label that can be most of label/version string you want
* Image name is a user defined string to identify your image
* "Image role" can be: 
  * `devsecops` for the predefined role `devsecops` ( playbook `playbook-devsecops.yaml`)
  * `offsec` for the predefined role `offsec` ( playbook `playbook-offsec.yaml`)
  * any other role would invoke a playbook `playbook-<role name>.yaml` in `resources` or `my-resources`, allowing you to build your custom image suited to your needs

All playbooks are searched first in `my-resources` folder, and then in `resources`. If playbook file is not found according to the role, the base image will be built ( playbook `playbook.yaml`).

### Example

#### Create an archlinux image with role `devsecops`

```shell
vol build -image test_image -version 1.0.1 -Distribution arch -role devsecops
```

This will launch the build process to ceate an image:

1. pull the latest archlinux image
2. install ansible
3. launch playbook `playbook-devsecops.yaml`
4. execute all roles specified by `playbook-devsecops.yaml`

This will take a few minutes to build this image named `test_image:1.0.1`

#### list the build images

```shell
vol lsi
```

```
ℹ️ Images :
+------------------+--------------+-----------+------------------+---------+
| Name             | Distribution | Role      | BuildDate        | Size    |
+==================+==============+===========+==================+=========+
| test_image:1.0.1 | arch         | devsecops | 2025-09-10 01:23 | 5 GB    |
+------------------+--------------+-----------+------------------+---------+
```

#### Create a container based on image `test_image:1.0.1`

```shell
vol start -container test_container -image test_image:1.0.1 -WithGui
```

You will get a zsh shell on this newly created container `test_container`. Since you have allowed GUI application with `-WithGui` you can start `firefox` for example.

#### list the available containers

```shell
vol ls
```

```
ℹ️ Containers :
+----------------+--------+------------------+-----------+------+-----+------------------+------------------+
| Name           | State  | Image            | Role      | Gui  | Vpn | Created          | LastStart        |
+================+========+==================+===========+======+=====+==================+==================+
| test_container | exited | test_image:1.0.1 | devsecops | true |     | 2025-09-10 01:25 | 2025-09-10 01:25 |
+----------------+--------+------------------+-----------+------+-----+------------------+------------------+
```

### open a new sesson 

If you have closed your session (or rebooted your computer), or just want to open a new session :

```shell
vol start -container test_container
```

### Volumes & Workspaces

- Data volumes can be created and **shared among multiple containers**.
- Every container has a `workspace` folder mounted from the host, allowing for **easy file exchange** and persistence.

## Architecture

- **Container Engine:** Podman (runs rootless under user context), should be compatible with docker
- **Configuration Management:** Ansible for reliable, reproducible provisioning
- **Host System:** Windows (via PowerShell scripting), leveraging WSL

## Limitations & known issues

- **Windows folder sharing:** When host folders are mounted into containers via Podman/Docker, the underlying filesystems differ (NTFS vs. Linux). As a result, running `chown` or `chmod` inside the container on these volumes may have cause some issues on some applications in the container. This is a known limitation of cross-platform volume, and impact volumes `workspace`, `resources`, and `my-resources`.

## Contributing

Contributions, issues, and feature requests are welcome! Please open an issue or submit a pull request on GitHub.

## License

MIT License. See [LICENSE](LICENSE) for more information.

*Volund brings reproducible, isolated, and versatile workspaces to your Windows environment with minimal setup and maximum scalability.*
