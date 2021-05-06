terraform {
  required_providers {
    vsphere = {
      source = "hashicorp/vsphere"
      version = "1.24.3"
    }
  }
  backend "s3" {
    bucket = "pvt-tf-state"
    key    = "terraform.state"
    region = "eu-central-1"
    encrypt  = true
    dynamodb_table = "terraform"
  }
}

provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  # if you have a self-signed cert
  allow_unverified_ssl = true
}


data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.vsphere_resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.vsphere_vm_portgroup
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.vsphere_vm_template
  datacenter_id = data.vsphere_datacenter.dc.id
}


resource "vsphere_virtual_machine" "vm" {
  name             = var.vsphere_vm_name
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = var.vsphere_folder
  annotation       = data.vsphere_virtual_machine.template.annotation

  num_cpus = 8
  memory   = var.vsphere_vm_memory 
  guest_id = var.vsphere_vm_guest 
  cpu_hot_add_enabled = true
  memory_hot_add_enabled = true

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label = "disk0"
    size  = var.vsphere_vm_disksize
  }

  disk {
    label = "disk1"
    size  = 5
    unit_number = 1
  }
 
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    linked_clone  = var.linked_clone
    timeout       = var.timeout
  }
}
output ip {
  value = vsphere_virtual_machine.vm.default_ip_address
}

output name {
  value = vsphere_virtual_machine.vm.name
}
