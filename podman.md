# Podman installation and start

1. Prerequisites 
   
* Podman installed on Windows
* WSL2 activated
* A valid .ovpn configuration file for your VPN, with any certificates required

2. Initialising Podman with WSL2

  1. Open a terminal
  2. Start the Podman service for WSL2 :

```sh
podman machine init
podman machine start
```

This creates and starts a lightweight VM to run Podman.

# The great purge

It is possible to purge all podman stuff, including images, volumes, containers, etc.

**Be aware that there is no recovery option after this! Be sure of what you do !**

List existing wsl VMs :

```sh
wsl --list --all
```

You should see :

```txt
...
podman-machine-default
...
```

Delete this machine:

```sh
podman machine rm podman-machine-default --force
```

You can now recreate podman :

```sh
podman machine init
```

# Troubleshhot

## Failed to start podman

```sh
podman machine start
```

```txt
Starting machine "podman-machine-default"
Il n’existe aucune distribution avec le nom fourni.
Code d'erreur : Wsl/Service/WSL_E_DISTRO_NOT_FOUND
Error: the WSL bootstrap script failed: command C:\Users\xxxxxxxx\AppData\Local\Microsoft\WindowsApps\wsl.exe [-u root -d podman-machine-default /root/bootstrap] failed: exit status 0xffffffff
```

Deletes any remnants of the Podman machine (`podman-*`)

Sometimes Podman still thinks the machine exists even though WSL has lost it. To reset: 

```sh
podman machine rm podman-machine-default --force
```

Ignore errors if the VM no longer exists.

You can now recreate podman :

```sh
podman machine init
```
