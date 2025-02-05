# Development Environment

## Requirements

1. [Oracle VirtualBox](https://www.virtualbox.org/) 7.1+.
1. [HashiCorp Vagrant](https://developer.hashicorp.com/vagrant/install) 2.4.2+.
1. All commands and paths assume current directory is the one where this README is located.
1. All commands assume usage of Bash. Git Bash on Windows is tested and supported too.

## Usage overview

Additional virtual disks required by [Vagrantfile](Vagrantfile) can be found in [disks.zip](disks.zip).
Vagrant looks for these additional disks at `%USERPROFILE%\VirtualBox VMs` directory when creating virtual machine,
so consider copying these files from [disks.zip](disks.zip) if they don't exist in the expected location.

The disks.zip includes:

1. ws.vmdk

    * Intended to be used for the workspace files, like documents, source code and any other files,
      which need to be preserved b/w creation of VMs.
    * Is mounted during creation of VM as /ws.

1. repository.vmdk

    * Intended to be used as a cache for downloaded third-party files,
      like Maven local repository (Maven is configured to use this disk),
      which need to be preserved b/w creation of VMs.
    * Is mounted during creation of VM as /repository.

1. containers.vmdk

    * Intended to be used for containers and container images, which need to be preserved b/w creation of VMs.
    * Is mounted during creation of VM as /containers.
    * Docker is configured to use /containers/docker as its graph storage.

These host folders are mapped into VM by VirtualBox (shared folders are created by Vagrant and can be customized in [Vagrantfile](Vagrantfile)):

| # | Host directory | Guest directory |
|---|----------------|-----------------|
| 1 | %USERPROFILE%\Documents | /media/sf_documents |
| 2 | %USERPROFILE%\Downloads | /media/sf_downloads |
| 3 | %USERPROFILE%\OneDrive | /media/sf_onedrive |
| 4 | %USERPROFILE%\ws | /media/sf_ws |

Optional files for customization of virtual machine:

| # | Location of file | Description |
|---|------------------|-------------|
| 1 | src/content/user.sh | Shell script defining user name, password and email |
| 2 | src/content/user.png | OS user account avatar |
| 3 | src/content/.ssh/id_rsa | SSH RSA private key |
| 4 | src/content/.ssh/id_ed\* | SSH EdDSA private key |
| 5 | src/content/.ssh/known_hosts | SSH known_hosts configuration file |
| 6 | src/content/.ssh/config | SSH main configuration file |
| 7 | src/content/bash/.bash_aliases | Additional Bash aliases. If some alias uses the same name as existing one then it overrides existing alias |
| 8 | src/content/.docker/config.json | Docker authentication data |
| 9 | src/content/idea/idea.key | IntelliJ IDEA offline license key |
| 10 | src/content/rider/rider.key | JetBrains Rider offline license key |
| 11 | src/content/goland/goland.key | GoLand offline license key |
| 12 | src/content/clion/clion.key | CLion offline license key |
| 13 | src/content/login/.netrc | The [.netrc](https://www.gnu.org/software/inetutils/manual/html_node/The-_002enetrc-file.html) file |

`src/content/user.sh` script should look like

```bash
#!/bin/bash -eux

# Name of OS account
MY_USER=username
# Password of OS account
MY_PASSWORD=password
# Full name of user for OS account and for Git
MY_NAME="FirstName LastName"
# Email for Git
MY_EMAIL="firstname.lastname@localdomain.local"
# User time zone (available time zones can be found in /usr/share/zoneinfo folder)
# For India it could be: Asia/Calcutta
# For US it could be: US/Eastern (other possible US timezones can be found in /usr/share/zoneinfo/US folder)
MY_TIMEZONE="Europe/Moscow"
```

## VM creation

```bash
vagrant up
```

## VM removal

### VM removal using Vagrant

Stop VM using Vagrant [halt](https://developer.hashicorp.com/vagrant/docs/cli/halt) command,
unmount drives with persistent data using [umount.sh](umount.sh) script and destroy VM
using Vagrant [destroy](https://developer.hashicorp.com/vagrant/docs/cli/destroy) command:

```bash
vagrant halt && ./umount.sh && vagrant destroy -f
```

### Manual VM removal

Steps:

1. Stop VM either using Vagrant [halt](https://developer.hashicorp.com/vagrant/docs/cli/halt) command:
    ```bash
    vagrant halt
    ```
    or using [VirtualBox Manager](https://www.virtualbox.org/manual/topics/Introduction.html#frontends).
1. Unmount drives with persistent data using [umount.sh](umount.sh) script (or using [umount.bat](umount.bat) script for Windows Command Prompt):
    ```bash
    ./umount.sh
    ```
1. [Remove VM](https://www.virtualbox.org/manual/topics/Introduction.html#intro-removing) using
    [VirtualBox Manager](https://www.virtualbox.org/manual/topics/Introduction.html#frontends).
    Feel free to chose "Delete all files" or "Remove only" depending on desired result.
1. Remove [.vagrant](.vagrant) directory to not confuse Vagrant next time it will be used:
    ```bash
    rm -rf .vagrant
    ```
