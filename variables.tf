variable "vnet_address_space" {
  description = "The address space for the virtual network"
  default     = ["192.168.208.0/16"]
}

variable "vpngw_address_space" {
  description = "The address space for the local network gateway"
  default = ["192.168.100.0/26", "192.168.102.64/27", "192.168.103.128/27"]
}

# Virtual Network "emsd-doba-vnet" Subnet Addresses

variable "gatewaySubnet_address_space" {
  description = "The address space for the GatewaySubnet"
  default = ["192.168.211.0/24"]
}

variable "agenttier-subnet_address_space" {
  description = "The address space for the agenttier-subnet"
  default = ["192.168.210.0/24"]
}

variable "webtier-subnet_address_space" {
  description = "The address space for the webtier-subnet"
  default = ["192.168.209.0/24"]
}

variable "waf-Subnet-v2_address_space" {
  description = "The address space for the WAF-Subnet-v2"
  default = ["192.168.213.0/24"]
}

# Set IP address for Local Network Gateway "DOBA_EMSD_VPN_Gateway"
variable "lngw_ip_address" {
  description = "The IP Address space for the Local Network Gateway DOBA_EMSD_VPN_Gateway"
  default = "223.197.189.249"
}