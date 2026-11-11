resource "azurerm_resource_group" "emsd_doba" {
  name     = "emsd_doba"
  location = "East Asia"
}

# ========================================================================================
# Section C
# ========================================================================================

# The Virtual Network "emsd-doba-vnet"

resource "azurerm_virtual_network" "emsd-doba-vnet" {
  name                = "emsd-doba-vnet"

  # Set address space for vnet
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.emsd_doba.location
  resource_group_name = azurerm_resource_group.emsd_doba.name
}

resource "azurerm_public_ip" "DOBA_Vnet_Gateway-ip" {
  name                = "DOBA_Vnet_Gateway-ip"
  location            = azurerm_resource_group.emsd_doba.location
  resource_group_name = azurerm_resource_group.emsd_doba.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Subnets Section of Virtual Network "emsd-doba-vnet"

resource "azurerm_subnet" "GatewaySubnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.emsd_doba.name
  virtual_network_name = azurerm_virtual_network.emsd-doba-vnet.name
  # Set address space for subnet GatewaySubnet
  address_prefixes     = var.gatewaySubnet_address_space
}

resource "azurerm_subnet" "emsd-doba-agenttier-subnet" {
  name                 = "emsd-doba-agenttier-subnet"
  resource_group_name  = azurerm_resource_group.emsd_doba.name
  virtual_network_name = azurerm_virtual_network.emsd-doba-vnet.name
  # Set address space for subnet agenttier-subnet
  address_prefixes     = var.agenttier-subnet_address_space
}

resource "azurerm_subnet" "emsd-doba-webtier-subnet" {
  name                 = "emsd-doba-webtier-subnet"
  resource_group_name  = azurerm_resource_group.emsd_doba.name
  virtual_network_name = azurerm_virtual_network.emsd-doba-vnet.name
  # Set address space for subnet webtier-subnet
  address_prefixes     = var.webtier-subnet_address_space
}

resource "azurerm_subnet" "Web-WAF-Subnet-v2" {
  name                 = "Web-WAF-Subnet-v2"
  resource_group_name  = azurerm_resource_group.emsd_doba.name
  virtual_network_name = azurerm_virtual_network.emsd-doba-vnet.name
  # Set address space for subnet Web-WAF-Subnet-v2
  address_prefixes     = var.waf-Subnet-v2_address_space
}

# The Virtual Network Gateway DOBA_Vnet_Gateway

resource "azurerm_virtual_network_gateway" "DOBA_Vnet_Gateway" {
  name                = "DOBA_Vnet_Gateway"
  location            = azurerm_resource_group.emsd_doba.location
  resource_group_name = azurerm_resource_group.emsd_doba.name

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "VpnGw1AZ"

  ip_configuration {
    name                          = "DOBA_Vnet_Gateway-ip"
    public_ip_address_id          = azurerm_public_ip.DOBA_Vnet_Gateway-ip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.GatewaySubnet.id
  }
}

# The Local Network Gateway DOBA_EMSD_VPN_Gateway

resource "azurerm_local_network_gateway" "DOBA_EMSD_VPN_Gateway" {
  name                = "DOBA_EMSD_VPN_Gateway"
  location            = azurerm_resource_group.emsd_doba.location
  resource_group_name = azurerm_resource_group.emsd_doba.name
  
  # Set IP address for Local Network Gateway "DOBA_EMSD_VPN_Gateway"
  gateway_address     = var.lngw_ip_address
  
  # Set address space for Local Network Gateway "DOBA_EMSD_VPN_Gateway"
  address_space       = var.vpngw_address_space
}

resource "azurerm_virtual_network_gateway_connection" "vpn_connection" {
  name                       = "vnet-to-onprem-connection"
  location                   = azurerm_resource_group.emsd_doba.location
  resource_group_name        = azurerm_resource_group.emsd_doba.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.DOBA_Vnet_Gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.DOBA_EMSD_VPN_Gateway.id

  shared_key                 = "YourSecurePreSharedKeyHere123!" # Must match the key configured on your physical router
}

# The frontend ip address for DOBA_Web-WAF-v2

resource "azurerm_public_ip" "DOBA_Web-WAF-ip-v2" {
  name                = "DOBA_Web-WAF-ip-v2"
  location            = azurerm_resource_group.emsd_doba.location
  resource_group_name = azurerm_resource_group.emsd_doba.name
  allocation_method   = "Static"
  sku                 = "Standard"
  idle_timeout_in_minutes = 4
}

# The different routing settings for application gateway "DOBA_Web-WAF-v2"
locals {
  path_rules = [
    {
      name          = "FEGrp1"
      paths         = ["/MMS_TW*", "/ATM_TM*", "/AFM_FL*", "/CML*", "/CRL_KT*", "/GMS_KB*", "/GWM_FT*", "/IMS*", "/KBI_KB*", "/KMS_TY*", "/SML_FT*", "/SYL_TKW*", "/UCL*", "/WHL*",
      "/YWM_KC*", "/ZFG*", "/ANE_CSW*", "/OEM_FL*", "/ELM_ALC*", "/FML_TKW*", ]
      pool_name     = "appGatewayBackendFEGrp1"
      settings_name = "appGatewayBackendHttpSettings"
      redirect_name = null
    },
    {
      name          = "FEGrp2"
      paths         = ["/MSS_CSW*", "/VIM_KC*", "/GWM_CW*", "/AML_TM*", "/FWA_SS*", "/PML_TW*", "/DCH*", "/CIL_YL*", "/KLM_TW*", "/JCL*", "/BSL_KC*"]
      pool_name     = "appGatewayBackendFEGrp2"
      settings_name = "appGatewayBackendHttpSettings"
      redirect_name = null
    },
    {
      name          = "FEGrp-v2"
      paths         = ["/ABC*"]
      pool_name     = "appGatewayBackendFEGrp-v2"
      settings_name = "appGatewayBackendHttpSettings"
      redirect_name = null
    },
    {
      paths         = ["/*"] 
      pool_name     = null
      settings_name = null
      redirect_name = "Default_App"
    }
  ]
  # Flattens the path rules so that it can be used later in azurerm_application_gateway "DOBA_Web-WAF-v2"
  flattened_path_rules = flatten([
    for group in local.path_rules : [
      for p in group.paths : {
        path          = p
        pool_name     = try(group.pool_name, null)
        settings_name = try(group.settings_name, null)
        redirect_name = try(group.redirect_name, null)
      }
    ]
  ])
}


resource "azurerm_application_gateway" "DOBA_Web-WAF-v2" {
  name                = "DOBA_Web-WAF-v2"
  location            = azurerm_resource_group.emsd_doba.location
  resource_group_name = azurerm_resource_group.emsd_doba.name

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
  }

  gateway_ip_configuration {
    name      = "DOBA_Web-WAF-v2-ip-config"
    subnet_id = azurerm_subnet.Web-WAF-Subnet-v2.id
  }

  frontend_ip_configuration {
    name                 = "appGwPublicFrontendIpIPv4"
    public_ip_address_id = azurerm_public_ip.DOBA_Web-WAF-ip-v2.id
  }

  frontend_port {
    name = "port-443"
    port = 443
  }

  redirect_configuration {
    name                 = "Default_App"
    redirect_type        = "Permanent" # Or "Temporary", "Found", "SeeOther"
    target_url           = "https://www.gov.hk/tc/residents/transport/vehicle/bookvehicleexam.htm"
    include_path         = false
    include_query_string = false
  }
  
  # Backend address pools for application gateway DOBA_Web-WAF-v2

  backend_address_pool {
    name = "appGatewayBackendPool"
  }

  backend_address_pool {
    name = "appGatewayBackendFEGrp1"
  }

  backend_address_pool {
    name = "appGatewayBackendFEGrp2"
  }

  backend_address_pool {
    name = "appGatewayBackendFEGrp-v2"
  }

  # Backend address settings for Backend address pools in application gateway DOBA_Web-WAF-v2

  backend_http_settings {
        name                  = "appGatewayBackendHttpSettings"
        cookie_based_affinity = "Enabled"
        port                  = 80
        protocol              = "Http"
        request_timeout       = 60
  }

  ssl_certificate {
    name     = "car-testing.td.gov.hk"
    #======================================= TO DO
    #data     = filebase64("${path.module}/certificates/mycert.pfx")
    #password = "YourPfxPasswordHere"
    #======================================= TO DO
  }


  # SSL policy setup in listeners
  ssl_policy {
    policy_type          = "Predefined"
    policy_name          = "AppGwSslPolicy20220101"
    min_protocol_version = "TLSv1_2"
  }

  http_listener {
    name                           = "appGatewayHttpsListener"
    frontend_ip_configuration_name = "appGwPublicFrontendIpIPv4"
    frontend_port_name             = "port-443"
    protocol                       = "Https"
    ssl_certificate_name           = "car-testing.td.gov.hk"
  }

  # Routing rule for all 4 backend address pools

  url_path_map {
    name = "routing-map" 
    default_backend_address_pool_name = "appGatewayBackendPool"
    default_backend_http_settings_name = "appGatewayBackendHttpSettings"

    # Dynamically generates a path rule for every flattened path
    dynamic "path_rule" {
      for_each = local.flattened_path_rules
      content {
        # Names "/*" as "catch-all", and dynamically names all other paths
        name = path_rule.value.path == "/*" ? "Default-App" : trimsuffix(trimprefix(path_rule.value.path, "/"), "*")

        paths = [path_rule.value.path]

        # Conditionally assigns backend pool OR redirect config
        backend_address_pool_name   = path_rule.value.redirect_name == null ? path_rule.value.pool_name : null
        backend_http_settings_name  = path_rule.value.redirect_name == null ? path_rule.value.settings_name : null
        redirect_configuration_name = path_rule.value.redirect_name
      }
    }
  }

  request_routing_rule {
    name                       = "appgw-routing-rule"
    rule_type                  = "PathBasedRouting"
    http_listener_name         = "appGatewayHttpsListener"
    url_path_map_name          = "routing-map"
    priority                   = 1
  }
}

# ========================================================================================
# Section D
# ========================================================================================

# VM no.1 
resource "azurerm_network_interface" "doba-agt1-v2830" {
  name = "doba-agt1-v2830"
  resource_group_name = azurerm_resource_group.emsd_doba.name
  location            = azurerm_resource_group.emsd_doba.location

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.emsd-doba-agenttier-subnet.id
    private_ip_address_allocation = "Dynamic"
    # public_ip_address_id = 
  }
}

resource "azurerm_recovery_services_vault" "emsd_doba_recovery_vault" {
  name                = "emsd-doba-recovery-vault"
  location            = azurerm_resource_group.emsd_doba.location
  resource_group_name = azurerm_resource_group.emsd_doba.name
  sku                 = "Standard"
}

resource "azurerm_backup_policy_vm" "emsd_doba_backup_policy" {
  name                = "emsd-doba-daily-policy"
  resource_group_name = azurerm_resource_group.emsd_doba.name
  recovery_vault_name = azurerm_recovery_services_vault.emsd_doba_recovery_vault.name
  policy_type = "V2"
  instant_restore_retention_days = 2

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 30
  }
}

# Load Balancer for VM no.1
resource "azurerm_lb" "DOBA_LB_AgentAV_Std" {
  name                = "DOBA_LB_AgentAV_Std"
  location            = azurerm_resource_group.emsd_doba.location
  resource_group_name = azurerm_resource_group.emsd_doba.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    subnet_id = azurerm_subnet.emsd-doba-agenttier-subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address = "192.168.210.4"
  }
}

# Backend Pools
resource "azurerm_lb_backend_address_pool" "DOBA_LB_Backend_pool" {
  name            = "DOBA_LB_Backend_pool"
  loadbalancer_id = azurerm_lb.DOBA_LB_AgentAV_Std.id
}

# 4. Health Probes
resource "azurerm_lb_probe" "DOBA_LB_Probe" {
  loadbalancer_id = azurerm_lb.DOBA_LB_AgentAV_Std.id
  name            = "DOBA_LB_Probe"
  port            = 80 # Change to the port your service runs on (e.g., 443)
}

# 5. Load Balancing Rule
resource "azurerm_lb_rule" "DOBA_LB_Rule" {
  loadbalancer_id                = azurerm_lb.DOBA_LB_AgentAV_Std.id
  name                           = "DOBA_LB_Rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.DOBA_LB_Backend_pool.id]
  probe_id                       = azurerm_lb_probe.DOBA_LB_Probe.id
}

resource "azurerm_lb_rule" "DOBA_LB_Rule_https" {
  loadbalancer_id                = azurerm_lb.DOBA_LB_AgentAV_Std.id
  name                           = "DOBA_LB_Rule_https"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.DOBA_LB_Backend_pool.id]
  probe_id                       = azurerm_lb_probe.DOBA_LB_Probe.id
}

# 6. Associate your VM's Network Interface to the Load Balancer Backend Pool
resource "azurerm_network_interface_backend_address_pool_association" "vm_lb_assoc" {
  network_interface_id    = azurerm_network_interface.doba-agt1-v2830.id
  ip_configuration_name   = "ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.DOBA_LB_Backend_pool.id
}


resource "azurerm_linux_virtual_machine" "DOBA-AGT1-v2" {
  name                  = "DOBA-AGT1-v2"
  resource_group_name   = azurerm_resource_group.emsd_doba.name
  location              = azurerm_resource_group.emsd_doba.location
  size                  = "Standard_D4lds_v5"
  admin_username        = "azureuser"

  network_interface_ids = [azurerm_network_interface.doba-agt1-v2830.id]

  os_disk {
    name                 = "DOBA-AGT1-disk-0"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

# VM no.2 
resource "azurerm_network_interface" "doba-agt2-v283" {
  name = "doba-agt2-v283"
  resource_group_name = azurerm_resource_group.emsd_doba.name
  location            = azurerm_resource_group.emsd_doba.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.emsd-doba-agenttier-subnet.id
    private_ip_address_allocation = "Dynamic"
    # public_ip_address_id = 
  }
}

resource "azurerm_linux_virtual_machine" "DOBA-AGT2-v2" { 
  name                  = "DOBA-AGT1-v2"
  resource_group_name   = azurerm_resource_group.emsd_doba.name
  location              = azurerm_resource_group.emsd_doba.location
  size                  = "Standard_D4lds_v5"
  admin_username        = "azureuser"

  network_interface_ids = [azurerm_network_interface.doba-agt2-v283.id]

  os_disk {
    name                 = "DOBA-AGT1-disk-0"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

