# module creates APIM infrastructure (minus app gateway) for project SIMS:64061
# Ben Briggs - Silversands

# Variables

variable network_resource_group_name {}
variable vnet_resource_group_name {}
variable virtual_network_name {}
variable network_security_group_name {}
variable apim_subnet {}
variable apim_subnetname {}
variable location {}
variable ag_subnet {}
variable agw_subnetname {}
variable hc_vm_subnet_id {}
variable hc_vm_name {}
variable hc_vm_admin_username {}
variable hc_vm_admin_password {}
variable relay_name {}
variable envtag {}
variable creatortag {}


# Create Subnets

resource "azurerm_subnet" "apimsubnet" {
  name                 = "${var.apim_subnetname}"
  resource_group_name  = "${var.vnet_resource_group_name}"
  virtual_network_name = "${var.virtual_network_name}"
  address_prefix       = "${var.apim_subnet}"

}

resource "azurerm_subnet" "frontend" {
  name                 = "${var.agw_subnetname}"
  resource_group_name  = "${var.vnet_resource_group_name}"
  virtual_network_name = "${var.virtual_network_name}"
  address_prefix       = "${var.ag_subnet}"
}

# Create NSG for APIM

resource "azurerm_network_security_group" "apimnsg" {
  name                = "${var.network_security_group_name}"
  location            = "${var.location}"
  resource_group_name = "${var.network_resource_group_name}"

    tags {
      Environment = "${var.envtag}"
      Partner = "${var.creatortag}"
    }
}

resource "azurerm_network_security_rule" "rule1" {
  name                        = "APIMAllowHttp"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = "${var.network_resource_group_name}"
  network_security_group_name = "${var.network_security_group_name}"
}

resource "azurerm_network_security_rule" "rule2" {
  name                        = "APIMAllow"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = "${var.network_resource_group_name}"
  network_security_group_name = "${var.network_security_group_name}"
}

resource "azurerm_network_security_rule" "rule3" {
  name                        = "ApimManagementEndpointAllow"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3443"
  source_address_prefix       = "APIManagement"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = "${var.network_resource_group_name}"
  network_security_group_name = "${var.network_security_group_name}"
}

resource "azurerm_subnet_network_security_group_association" "ApimNSGAssociation" {
  subnet_id                 = "${azurerm_subnet.apimsubnet.id}"
  network_security_group_id = "${azurerm_network_security_group.apimnsg.id}"
}

# Create Virtual Machine

resource "azurerm_network_security_group" "vmnsg" {
    name                = "${var.hc_vm_name}-nsg"
    location            = "${var.location}"
    resource_group_name = "${var.network_resource_group_name}"

    tags {
      Environment = "${var.envtag}"
      Partner = "${var.creatortag}"
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

    tags {
      Environment = "${var.envtag}"
      Partner = "${var.creatortag}"
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

    tags {
      Environment = "${var.envtag}"
      Partner = "${var.creatortag}"
    }
}

resource "azurerm_virtual_machine" "windowsvm" {
    name                  = "${var.hc_vm_name}"
    location              = "${var.location}"
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

    tags {
      Environment = "${var.envtag}"
      Partner = "${var.creatortag}"
    }
}

# Create relay

resource "azurerm_relay_namespace" "test" {
  name                = "${var.relay_name}"
  location            = "${var.location}"
  resource_group_name = "${var.network_resource_group_name}"

  sku {
    name = "Standard"
  }

  tags {
      Environment = "${var.envtag}"
      Partner = "${var.creatortag}"
  }

}
