# Base Vagrant Box for development VM based on Rocky Linux 9

[Packer](http://packer.io/intro/index.html) project for [Vagrant](https://www.vagrantup.com/) box with VirtualBox VM
containing development tools and based on Rocky Linux 9 with GNOME.

All paths given in this README are relative to the directory where this README is located.

## Build requirements

1. [Oracle VirtualBox](https://www.virtualbox.org/) 7.1.4+.
1. [HashiCorp Packer](http://packer.io/downloads.html) 1.11.2+.
1. [HashiCorp Vagrant](https://developer.hashicorp.com/vagrant/install) 2.4.2+.
1. All commands and paths assume current directory is the one where this README is located.
1. All commands assume usage of Bash. Git Bash on Windows is tested and supported too.

## Steps to build

1. Download prebuilt Virtual Appliance file with Rocky Linux 9 desktop - `rocky-desktop-x.y.z.ova` -
    or build it from [rocky-desktop](https://github.com/mabrarov/rocky-desktop) repository,
    then put Virtual Appliance file into the directory where this README is located.
1. Place [IntelliJ IDEA distribution for Linux](https://www.jetbrains.com/idea/download/?section=linux) in [cache](cache) directory.
    This file can be downloaded automatically during building Vagrant box if VPN is used.
    Otherwise, find the name of file in [src/scripts/bootstrap.sh](src/scripts/bootstrap.sh) and place that file manually.
1. Place [JetBrains Rider distribution for Linux](https://www.jetbrains.com/rider/download/#section=linux) in [cache](cache) directory.
    This file can be downloaded automatically during building Vagrant box if VPN is used.
    Otherwise, find the name of file in [src/scripts/bootstrap.sh](src/scripts/bootstrap.sh) and place that file manually.
1. Place [GoLand distribution for Linux](https://www.jetbrains.com/go/download/#section=linux) in [cache](cache) directory.
    This file can be downloaded automatically during building Vagrant box if VPN is used.
    Otherwise, find the name of file in [src/scripts/bootstrap.sh](src/scripts/bootstrap.sh) and place that file manually.
1. Place [CLion distribution for Linux](https://www.jetbrains.com/clion/download/#section=linux) in [cache](cache) directory.
    This file can be downloaded automatically during building Vagrant box if VPN is used.
    Otherwise, find the name of file in [src/scripts/bootstrap.sh](src/scripts/bootstrap.sh) and place that file manually.
1. Place [JetBrains plugins](https://plugins.jetbrains.com/) archive files in [cache](cache) directory.
    Some of these files can be downloaded automatically during building Vagrant box if VPN is used.
    The set of archive files (and download URLs) which need to be placed can be found in [src/scripts/bootstrap.sh](src/scripts/bootstrap.sh).
1. Run
    ```bash
    packer init rocky-dev.pkr.hcl && packer build rocky-dev.pkr.hcl
    ```
1. Find the built Vagrant box in output/rocky-dev-a.b.c.box, where `a.b.c` is value of `vm_version` variable in
    [rocky-dev.pkr.hcl](rocky-dev.pkr.hcl).

## Usage of built Vagrant Box

1. Import built Vagrant box by running command:
    ```bash
    vagrant box add --name rocky-dev output/rocky-dev-a.b.c.box
    ```
    where `a.b.c` is value of `vm_version` variable in [rocky-dev.pkr.hcl](rocky-dev.pkr.hcl).
1. Follow [../dev/README.md](../dev/README.md).

## Changing version of Vagrant box

1. Change default value of `vm_version` variable in [rocky-dev.pkr.hcl](rocky-dev.pkr.hcl).
1. Build new Vagrant box.

## Migrating to a new version of Rocky Linux 9 desktop OVA

1. Download prebuilt Virtual Appliance file with Rocky Linux 9 desktop - `rocky-desktop-x.y.z.ova` -
    or build it from [rocky-desktop](https://github.com/mabrarov/rocky-desktop) repository,
    then put Virtual Appliance file into the folder where this README is located.
1. Change version of base OVA file in Packer project - set default value of `base_ova_version` variable in [rocky-dev.pkr.hcl](rocky-dev.pkr.hcl) to `x.y.z`.
1. Build new Vagrant box.
