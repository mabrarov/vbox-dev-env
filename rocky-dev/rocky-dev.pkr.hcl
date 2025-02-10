packer {
  required_plugins {
    virtualbox = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/virtualbox"
    }
    vagrant = {
      version = ">= 1.1.5"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

variable "vm_name" {
  type        = string
  default     = "rocky-dev"
  description = "Name of Vagrant box"
}

variable "vm_version" {
  type        = string
  default     = "1.1.0"
  description = "Version of Vagrant box"
}

variable "vm_description" {
  type        = string
  default     = "Base box for dev VM"
  description = "Description of Vagrant box"
}

variable "base_ova_name" {
  type        = string
  default     = "rocky-desktop"
  description = "Name of base OVA"
}

variable "base_ova_version" {
  type        = string
  default     = "1.0.3"
  description = "Version of base OVA"
}

variable "base_ova_guest_os_username" {
  type        = string
  default     = "user"
  description = "Name of guest OS user"
}

variable "base_ova_guest_os_password" {
  type        = string
  default     = "user"
  description = "Password of guest OS user"
}

locals {
  provision_content_destination_dir = "/tmp/rocky-dev"
  cache_dir_shared_folder_name      = "cache"
}

source "virtualbox-ovf" "rocky-dev" {
  vm_name     = "${var.vm_name}-${var.vm_version}"
  source_path = "${var.base_ova_name}-${var.base_ova_version}.ova"
  export_opts = [
    "--manifest",
    "--vsys", "0",
    "--description", "${var.vm_description}",
    "--version", "${var.vm_version}"
  ]
  format               = "ova"
  headless             = false
  guest_additions_mode = "disable"
  boot_wait            = "10s"
  shutdown_command     = "echo '${var.base_ova_guest_os_username}' | sudo -S /sbin/halt -h -p"
  post_shutdown_delay  = "30s"
  ssh_username         = var.base_ova_guest_os_username
  ssh_password         = var.base_ova_guest_os_password
  ssh_port             = 22
  ssh_wait_timeout     = "10000s"
  keep_registered      = false
  output_directory     = "output-virtualbox-iso"
  skip_export          = false
  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--accelerate3d", "on"],
    ["modifyvm", "{{.Name}}", "--natdnsproxy1", "on"],
    ["modifyvm", "{{.Name}}", "--natdnshostresolver1", "on"],
    ["modifyvm", "{{.Name}}", "--accelerate3d", "off"],
    ["sharedfolder", "add", "{{.Name}}", "--name", local.cache_dir_shared_folder_name, "--hostpath", "${path.root}/cache", "--automount"]
  ]
  vboxmanage_post = [
    ["modifyvm", "{{.Name}}", "--natdnshostresolver1", "off"],
    ["modifyvm", "{{.Name}}", "--natdnsproxy1", "off"],
    ["sharedfolder", "remove", "{{.Name}}", "--name", local.cache_dir_shared_folder_name]
  ]
  virtualbox_version_file = ""
}

build {
  sources = ["virtualbox-ovf.rocky-dev"]
  provisioner "file" {
    source      = "src/content"
    destination = local.provision_content_destination_dir
  }
  provisioner "shell" {
    execute_command = "echo '${var.base_ova_guest_os_password}' | sudo -S env {{ .Vars }} {{ .Path }}"
    environment_vars = [
      "VM_USER=${var.base_ova_guest_os_username}",
      "VM_USER_GROUP=${var.base_ova_guest_os_username}",
      "PROVISION_CONTENT_DIR=${local.provision_content_destination_dir}",
      "CACHE_DIR=/media/sf_${local.cache_dir_shared_folder_name}"
    ]
    scripts = [
      "src/scripts/bootstrap.sh"
    ]
    pause_before = "10s"
  }
  post-processor "vagrant" {
    compression_level    = 9
    vagrantfile_template = "src/vagrantfile.template"
    output               = "output/${var.vm_name}-${var.vm_version}.box"
  }
}
