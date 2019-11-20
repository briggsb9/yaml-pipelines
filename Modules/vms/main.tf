# Module for creating a logical group of multiple windows VMs within an availabilty set. Includes auto join to domain.

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = var.resource_group_name
    }

    byte_length = 8
}

# Create Availability Set
resource "azurerm_availability_set" "as" {
    name                = "${var.service_short_name}-${var.availability_set_context}-AS"
    location            = var.location
    resource_group_name = var.resource_group_name
    managed = true
    tags = var.tags
}

# Create supporting resources for VM(s)

resource "azurerm_storage_account" "vmstorageaccount" {
    name                = "vmdiag${random_id.randomId.hex}"
    resource_group_name = var.resource_group_name
    location            = var.location
    account_replication_type = "LRS"
    account_tier = "Standard"
    enable_advanced_threat_protection = true
    tags = var.tags
}

resource "azurerm_network_interface" "nic" {
    for_each            = var.vm_user_properties
    name                = "${var.tags["Environment"]}-${var.service_short_name}${each.key}-nic"
    location            = "${var.location}"
    resource_group_name = "${var.resource_group_name}"
    dns_servers         = "${var.dns_servers}"
    tags = var.tags

    ip_configuration {
        name                          = "ipconfiguration"
        subnet_id                     = "${var.subnet_id}"
        private_ip_address_allocation = "Static"
        private_ip_address            = lookup(each.value, "Private_ip", "*")
  }
}

# Create virtual machine(s)

resource "azurerm_virtual_machine" "vm" {
    for_each              = var.vm_user_properties
    name                  = "${var.tags["Environment"]}-${var.service_short_name}${each.key}-VM"
    location              = "${var.location}"
    resource_group_name   = "${var.resource_group_name}"
    network_interface_ids = ["${azurerm_network_interface.nic[each.key].id}"]
    vm_size               = lookup(each.value, "VM_size", "*")
    availability_set_id   = "${azurerm_availability_set.as.id}"

    storage_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2019-Datacenter"
        version   = "latest"
    }

    storage_os_disk {
        name              = "${var.tags["Environment"]}-${var.service_short_name}${each.key}-OSDISK"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = var.os_disk_type
    }

    # creates data disk only if var.data_disk_type is specified.
    dynamic "storage_data_disk" {
        for_each = var.data_disk_type == "" ? [] : [1]
        content {
        name              = "${var.tags["Environment"]}-${var.service_short_name}${each.key}-DATADISK"
        create_option     = "Empty"
        lun               = 0
        disk_size_gb      = var.data_disk_size_gb
        managed_disk_type = var.data_disk_type
        caching           = "None"
        }
    }

    os_profile {
        computer_name  = "${var.tags["Environment"]}-${var.service_short_name}${each.key}-VM"
        admin_username = "${var.admin_username}"
        admin_password = "${var.admin_password}"
    }

    os_profile_windows_config {
        enable_automatic_upgrades = true
        provision_vm_agent = true
    }

    boot_diagnostics {
        enabled     = "true"
        storage_uri = "${azurerm_storage_account.vmstorageaccount.primary_blob_endpoint}"
    }

    tags = merge(map("Patchwindow", lookup(each.value, "Patchwindow", "*")), var.tags) 
}

/*
Enable backup - Not working due to Azure backend issue with soft delete on recovery services vault.

resource "azurerm_recovery_services_protected_vm" "vmprotect01" {
    for_each            = var.vm_user_properties
    resource_group_name = var.recovery_vault_resource_group_name
    recovery_vault_name = var.recovery_vault_name
    source_vm_id        = "${azurerm_virtual_machine.vm[each.key].id}"
    backup_policy_id    = var.backup_policy_id
}
*/

##########################################################
## Join VM to Active Directory Domain
##########################################################

resource "azurerm_virtual_machine_extension" "join-domain" {
  for_each             = var.vm_user_properties
  depends_on           = [azurerm_virtual_machine.vm]
  name                 = "join-domain"
  location             = var.location
  resource_group_name  = var.resource_group_name
  virtual_machine_name = "${var.tags["Environment"]}-${var.service_short_name}${each.key}-VM"
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"
  

  # NOTE: the `OUPath` field is intentionally blank, to put it in the Computers OU
  settings = <<SETTINGS
    {
        "Name": "${var.active_directory_domain}",
        "OUPath": "",
        "User": "${var.active_directory_domain}\\${var.active_directory_username}",
        "Restart": "true",
        "Options": "3"
    }
SETTINGS

  protected_settings = <<SETTINGS
    {
        "Password": "${var.active_directory_password}"
    }
SETTINGS
}