# module creates APIM infrastructure (minus app gateway) for project SIMS:64061

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
variable partnertag {}


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
      Partner = "${var.partnertag}"
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

/*
# Create Application Gateway

resource "azurerm_public_ip" "pubip" {
  name                = "${var.app_gateway_name}-pip"
  resource_group_name = "${var.network_resource_group_name}"
  location            = "${var.location}"
  allocation_method   = "Dynamic"
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "APIMBackendPool"
  frontend_port_name             = "AppGatewayFrontend443"
  frontend_ip_configuration_name = "AppGatewayFrontendIP"
  http_setting_name_1            = "APIM_PoolSetting"
  http_setting_name_2            = "APIM_PoolPortalSetting"
  http_setting_name_3            = "APIM_PoolManSetting"
  http_setting_name_4            = "APIM_PoolSCMSetting"
  listener_name_1                = "APIM_PROXY_UAT"
  listener_name_2                = "APIM_SCM_UAT"
  listener_name_3                = "APIM_Management_UAT"
  listener_name_4                = "APIM_Portal_UAT"
  request_routing_rule_name_1    = "APIM_PROXY_SIT_RULE"
  request_routing_rule_name_2    = "APIM_MANAGEMENT_SIT_RULE"
  request_routing_rule_name_3    = "APIM_SCM_SIT_RULE"
  request_routing_rule_name_4    = "APIM_PORTAL_SIT_RULE"
  probe_name_1                   = "apimportalprobe"
  probe_name_2                   = "apimproxyprobe"
  probe_name_3                   = "apimmanprobe"
  probe_name_4                   = "apimscmprobe"
}

resource "azurerm_application_gateway" "network" {
  name                = "${var.app_gateway_name}"
  resource_group_name = "${var.network_resource_group_name}"
  location            = "${var.location}"

  sku {
    name     = "WAF_Medium"
    tier     = "WAF"
    capacity = 1
  }

  waf_configuration {
    enabled          = "true"
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.0"
  }

  gateway_ip_configuration {
    name      = "Subnet"
    subnet_id = "${azurerm_subnet.frontend.id}"
  }

  frontend_port {
    name = "${local.frontend_port_name}"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "${local.frontend_ip_configuration_name}"
    public_ip_address_id = "${azurerm_public_ip.pubip.id}"
  }

  backend_address_pool {
    name = "${local.backend_address_pool_name}"
  }

  backend_http_settings {
    name                  = "${local.http_setting_name_1}"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 180
  }

  probe {
    name                = "${local.probe_name_1}"
    protocol            = "http"
    path                = "/"
    host                = "${azurerm_app_service.app-service-westus.name}.azurewebsites.net"
    interval            = "30"
    timeout             = "30"
    unhealthy_threshold = "3"
  }


  http_listener {
    name                           = "${local.listener_name_1}"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
    frontend_port_name             = "${local.frontend_port_name}"
    protocol                       = "Https"
    ssl_certificate                = ""
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name}"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}"
    backend_address_pool_name  = "${local.backend_address_pool_name}"
    backend_http_settings_name = "${local.http_setting_name}"
  }
}

*/

# Create Virtual Machine

resource "azurerm_network_security_group" "vmnsg" {
    name                = "${var.hc_vm_name}-nsg"
    location            = "${var.location}"
    resource_group_name = "${var.network_resource_group_name}"

    tags {
      Environment = "${var.envtag}"
      Partner = "${var.partnertag}"
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
      Partner = "${var.partnertag}"
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
      Partner = "${var.partnertag}"
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
      Partner = "${var.partnertag}"
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
      Partner = "${var.partnertag}"
  }

}
