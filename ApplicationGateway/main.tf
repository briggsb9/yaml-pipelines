# Variables

variable app_gateway_name {}
variable resource_group_name {}
variable location {}
variable enviroment {}
variable subnet_id {}
variable ssl_certificate_password {}


# Create Application Gateway 

# Create App Gateway IP
resource "azurerm_public_ip" "pubip" {
  name                = "${var.app_gateway_name}-pip"
  resource_group_name = "${var.resource_group_name}"
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
  listener_name_1                = "APIM_PROXY_${var.enviroment}"
  listener_name_2                = "APIM_Portal_${var.enviroment}"
  listener_name_3                = "APIM_Management_${var.enviroment}"
  listener_name_4                = "APIM_SCM_${var.enviroment}"
  request_routing_rule_name_1    = "APIM_PROXY_UAT_RULE"
  request_routing_rule_name_2    = "APIM_PORTAL_${var.enviroment}_RULE"
  request_routing_rule_name_3    = "APIM_MANAGEMENT_${var.enviroment}_RULE"
  request_routing_rule_name_4    = "APIM_SCM_${var.enviroment}_RULE"
  probe_name_1                   = "apimproxyprobe"
  probe_name_2                   = "apimportalprobe"
  probe_name_3                   = "apimmanprobe"
  probe_name_4                   = "apimscmprobe"
}

resource "azurerm_application_gateway" "network" {
  name                = "${var.app_gateway_name}"
  resource_group_name = "${var.resource_group_name}"
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
    subnet_id = "${var.subnet_id}"
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
        name                        = "${local.http_setting_name_1}"
        cookie_based_affinity       = "Disabled"
        port                        = 443
        protocol                    = "Https"
        request_timeout             = 180
        probe_name                  = "${local.probe_name_1}"
        authentication_certificate {
            name = "${var.enviroment}BackendCer"
            data = "${base64encode(file("${var.enviroment}api.cer"))}"
        }
  }

  probe {
    name                = "${local.probe_name_1}"
    protocol            = "https"
    path                = "/status-0123456789abcdef"
    host                = "apim-shared.api.${var.enviroment}.nwl.co.uk"
    interval            = "30"
    timeout             = "120"
    unhealthy_threshold = "8"

    match {
        status_code     = "200-399"
    }
  }

  http_listener {
    name                           = "${local.listener_name_1}"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
    frontend_port_name             = "${local.frontend_port_name}"
    hostname                       = "apim-shared.api.${var.enviroment}.nwl.co.uk"
    protocol                       = "Https"
    ssl_certificate {
        name     = "${var.enviroment}Wildcard"
        data     = "${base64encode(file("${var.enviroment}api.pfx"))}"
        password = "${var.ssl_certificate_password}"
    }
  }

  request_routing_rule {
    name                       = "APIM_PROXY_UAT_RULE"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name_1}"
    backend_address_pool_name  = "${local.backend_address_pool_name}"
    backend_http_settings_name = "${local.http_setting_name_1}"
  }
}