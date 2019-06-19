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
variable relay_name {}
variable envtag {}
variable creatortag {}


# Create Subnets

resource "azurerm_subnet" "apimsubnet" {
  name                 = "${var.apim_subnetname}"
  resource_group_name  = "${var.vnet_resource_group_name}"
  virtual_network_name = "${var.virtual_network_name}"
  address_prefix       = "${var.apim_subnet}"
  network_security_group_id = "${azurerm_network_security_group.apimnsg.id}"

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

    tags = {
      Environment = "${var.envtag}"
      Creator = "${var.creatortag}"
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

# Create relay

resource "azurerm_relay_namespace" "test" {
  name                = "${var.relay_name}"
  location            = "${var.location}"
  resource_group_name = "${var.network_resource_group_name}"

  sku {
    name = "Standard"
  }

  tags = {
      Environment = "${var.envtag}"
      Creator = "${var.creatortag}"
  }

}
