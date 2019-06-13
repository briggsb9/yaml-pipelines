# module creates an application gateway for project SIMS:64061
# Ben Briggs - Silversands

# Variables

variable resource_group_name {}
variable location {}
variable enviroment_uppercase {}
variable subnet_id {}
variable ssl_certificate_password {}
variable proxy_host_name {}
variable portal_host_name {}
variable management_host_name {}
variable scm_host_name {}
variable auth_certificate_name_cer {}
variable ssl_certificate_name_pfx {}
variable appgw_public_ip_name {}
variable appgw_name {}
variable envtag {}
variable creatortag {}

# Create Application Gateway 

# Create App Gateway IP
resource "azurerm_public_ip" "pubip" {
  name                = "${var.appgw_public_ip_name}"
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
  listener_name_1                = "APIM_PROXY_${var.enviroment_uppercase}"
  listener_name_2                = "APIM_Portal_${var.enviroment_uppercase}"
  listener_name_3                = "APIM_Management_${var.enviroment_uppercase}"
  listener_name_4                = "APIM_SCM_${var.enviroment_uppercase}"
  request_routing_rule_name_1    = "APIM_PROXY_${var.enviroment_uppercase}_RULE"
  request_routing_rule_name_2    = "APIM_PORTAL_${var.enviroment_uppercase}_RULE"
  request_routing_rule_name_3    = "APIM_MANAGEMENT_${var.enviroment_uppercase}_RULE"
  request_routing_rule_name_4    = "APIM_SCM_${var.enviroment_uppercase}_RULE"
  probe_name_1                   = "apimproxyprobe"
  probe_name_2                   = "apimportalprobe"
  probe_name_3                   = "apimmanprobe"
  probe_name_4                   = "apimscmprobe"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "${var.appgw_name}"
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
    request_body_check = "false"
    exclusion {
      match_variable = "RequestArgNames"
      selector_match_operator = "Equals"
      selector = "docs_query"
      }
    exclusion {
      match_variable = "RequestArgNames"
      selector_match_operator = "Equals"
      selector = "docs_url"
      }
  }
  
  ssl_policy {
    disabled_protocols = ["TLSv1_0", "TLSv1_1"]
  }

  gateway_ip_configuration {
    name      = "Subnet"
    subnet_id = "${var.subnet_id}"
  }

  ssl_certificate {
    name     = "${var.enviroment_uppercase}Wildcard"
    data     = "${filebase64("${var.ssl_certificate_name_pfx}")}"
    password = "${var.ssl_certificate_password}"
  }

  authentication_certificate {
    name = "${var.enviroment_uppercase}BackendCer"
    data = "${filebase64("${var.auth_certificate_name_cer}")}"
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
        name = "${var.enviroment_uppercase}BackendCer"
    }
  }

  backend_http_settings {
    name                        = "${local.http_setting_name_2}"
    cookie_based_affinity       = "Disabled"
    port                        = 443
    protocol                    = "Https"
    request_timeout             = 180
    probe_name                  = "${local.probe_name_2}"

    authentication_certificate {
        name = "${var.enviroment_uppercase}BackendCer"
    }
  }

  backend_http_settings {
    name                        = "${local.http_setting_name_3}"
    cookie_based_affinity       = "Disabled"
    port                        = 443
    protocol                    = "Https"
    request_timeout             = 180
    probe_name                  = "${local.probe_name_3}"

    authentication_certificate {
        name = "${var.enviroment_uppercase}BackendCer"
    }
  }

  backend_http_settings {
    name                        = "${local.http_setting_name_4}"
    cookie_based_affinity       = "Disabled"
    port                        = 443
    protocol                    = "Https"
    request_timeout             = 180
    probe_name                  = "${local.probe_name_4}"

    authentication_certificate {
        name = "${var.enviroment_uppercase}BackendCer"
    }
  }

  probe {
    name                = "${local.probe_name_1}"
    protocol            = "https"
    path                = "/status-0123456789abcdef"
    host                = "${var.proxy_host_name}"
    interval            = "30"
    timeout             = "120"
    unhealthy_threshold = "8"

    match {
        status_code     = ["200-399"]
        body            = ""
    }
  }

  probe {
    name                = "${local.probe_name_2}"
    protocol            = "https"
    path                = "/signin"
    host                = "${var.portal_host_name}"
    interval            = "60"
    timeout             = "300"
    unhealthy_threshold = "8"

    match {
        status_code     = ["200-399"]
        body            = ""
    }  
  }

  probe {
    name                = "${local.probe_name_3}"
    protocol            = "https"
    path                = "/apis?api-version=2018-01-01"
    host                = "${var.management_host_name}"
    interval            = "30"
    timeout             = "120"
    unhealthy_threshold = "8"

    match {
        status_code     = ["200-399"]
        body            = ""
    }  
  }

  probe {
    name                = "${local.probe_name_4}"
    protocol            = "https"
    path                = "/"
    host                = "${var.scm_host_name}"
    interval            = "30"
    timeout             = "120"
    unhealthy_threshold = "8"

    match {
        status_code     = ["200-399"]
        body            = ""
    }  
  }

  http_listener {
    name                           = "${local.listener_name_1}"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
    frontend_port_name             = "${local.frontend_port_name}"
    host_name                      = "${var.proxy_host_name}"
    protocol                       = "Https"
    ssl_certificate_name           = "${var.enviroment_uppercase}Wildcard"
  }

  http_listener {
    name                           = "${local.listener_name_2}"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
    frontend_port_name             = "${local.frontend_port_name}"
    host_name                      = "${var.portal_host_name}"
    protocol                       = "Https"
    ssl_certificate_name           = "${var.enviroment_uppercase}Wildcard"
  }

  http_listener {
    name                           = "${local.listener_name_3}"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
    frontend_port_name             = "${local.frontend_port_name}"
    host_name                      = "${var.management_host_name}"
    protocol                       = "Https"
    ssl_certificate_name           = "${var.enviroment_uppercase}Wildcard"
  }

  http_listener {
    name                           = "${local.listener_name_4}"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
    frontend_port_name             = "${local.frontend_port_name}"
    host_name                      = "${var.scm_host_name}"
    protocol                       = "Https"
    ssl_certificate_name           = "${var.enviroment_uppercase}Wildcard"
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name_1}"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name_1}"
    backend_address_pool_name  = "${local.backend_address_pool_name}"
    backend_http_settings_name = "${local.http_setting_name_1}"
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name_2}"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name_2}"
    backend_address_pool_name  = "${local.backend_address_pool_name}"
    backend_http_settings_name = "${local.http_setting_name_2}"
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name_3}"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name_3}"
    backend_address_pool_name  = "${local.backend_address_pool_name}"
    backend_http_settings_name = "${local.http_setting_name_3}"
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name_4}"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name_4}"
    backend_address_pool_name  = "${local.backend_address_pool_name}"
    backend_http_settings_name = "${local.http_setting_name_4}"
  }

  tags = {
    Environment = "${var.envtag}"
    Creator = "${var.creatortag}"
    }
}
