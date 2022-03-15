terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.97.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "wellsjp" {
  name     = "wellsjp"
  location = "Japan East"
}

module "linuxservers" {
  source              = "Azure/compute/azurerm"
  resource_group_name = azurerm_resource_group.wellsjp.name
  vm_os_simple        = "UbuntuServer"
  public_ip_dns       = ["wellslinuxservervip"]
  vnet_subnet_id      = module.network.vnet_subnets[0]
  vm_size             = "Standard_B1ls"
  remote_port         = "22"
  depends_on = [azurerm_resource_group.wellsjp]
}

module "network" {
  source              = "Azure/network/azurerm"
  resource_group_name = azurerm_resource_group.wellsjp.name
  subnet_prefixes     = ["10.0.1.0/24"]
  subnet_names        = ["subnet1"]

  depends_on = [azurerm_resource_group.wellsjp]
}

resource "azurerm_network_security_rule" "atlantis" {
  name                        = "atlantis"
  priority                    = 103
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "4141"
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.wellsjp.name
  network_security_group_name = module.linuxservers.network_security_group_name
}

resource "azurerm_network_security_rule" "http" {
  name                        = "atlantis"
  priority                    = 104
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.wellsjp.name
  network_security_group_name = module.linuxservers.network_security_group_name
}

output "linux_vm_public_name" {
  value = module.linuxservers.public_ip_dns_name
}
