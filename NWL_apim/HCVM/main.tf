# module creates Hybrid Connection Virtual machine for project SIMS:64061
# Ben Briggs - Silversands

# Variables

variable network_resource_group_name {}
variable network_security_group_name {}
variable location {}
variable hc_vm_subnet_id {}
variable hc_vm_name {}
variable hc_vm_admin_username {}
variable hc_vm_admin_password {}
variable env_tag {}
variable creator_tag {}
variable updatemanagement_tag {}
variable avset_name {}


# Create Virtual Machine

resource "azurerm_network_security_group" "vmnsg" {
    name                = "${var.hc_vm_name}-nsg"
    location            = "${var.location}"
    resource_group_name = "${var.network_resource_group_name}"

    tags = {
      Environment = "${var.env_tag}"
      Creator = "${var.creator_tag}"
    }
}

resource "azurerm_network_interface" "vmnic" {
    name                = "${var.hc_vm_name}-nic"
    location            = "${var.location}"
    resource_group_name = "${var.network_resource_group_name}"
    network_security_group_id = "${azurerm_network_security_group.vmnsg.id}"

    ip_configuration {
        name                          = "ipconfig1"
        subnet_id                     = "${var.hc_vm_subnet_id}"
        private_ip_address_allocation = "dynamic"
    }

    tags = {
      Environment = "${var.env_tag}"
      Creator = "${var.creator_tag}"
    }
}

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${var.network_resource_group_name}"
    }

    byte_length = 8
}

resource "azurerm_storage_account" "vmstorageaccount" {
    name                = "vmdiag${random_id.randomId.hex}"
    resource_group_name = "${var.network_resource_group_name}"
    location            = "${var.location}"
    account_replication_type = "LRS"
    account_tier = "Standard"

    tags = {
      Environment = "${var.env_tag}"
      Creator = "${var.creator_tag}"
    }
}

resource "azurerm_availability_set" "avset" {
     name                         = "${var.avset_name}"
     location                     = "${var.location}"
     resource_group_name          = "${var.network_resource_group_name}"
     platform_fault_domain_count  = 2
     platform_update_domain_count = 2
     managed                      = true
    
     tags = {
      Environment = "${var.env_tag}"
      Creator = "${var.creator_tag}"
    }
}

resource "azurerm_virtual_machine" "windowsvm" {
    name                  = "${var.hc_vm_name}"
    location              = "${var.location}"
    availability_set_id   = "${azurerm_availability_set.avset.id}"
    resource_group_name   = "${var.network_resource_group_name}"
    network_interface_ids = ["${azurerm_network_interface.vmnic.id}"]
    vm_size               = "Standard_B2s"

    storage_os_disk {
        name              = "${var.hc_vm_name}OsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter"
        version   = "latest"
    }

    os_profile {
        computer_name  = "${var.hc_vm_name}"
        admin_username = "${var.hc_vm_admin_username}"
        admin_password = "${var.hc_vm_admin_password}"
    }

    os_profile_windows_config {
        enable_automatic_upgrades = true
        provision_vm_agent = true
    
    }

    boot_diagnostics {
        enabled     = "true"
        storage_uri = "${azurerm_storage_account.vmstorageaccount.primary_blob_endpoint}"
    }

    tags = {
      Environment = "${var.env_tag}"
      Creator = "${var.creator_tag}"
      UpdateManagement = "${var.updatemanagement_tag}"
    }
}
