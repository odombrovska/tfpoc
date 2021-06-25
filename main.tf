# Using locals to definte the base name of the VM that will then be incremented using count.index.
# Adding common_tags that have environment name defined (can be set to anything).
locals {
  vm_name     = "${var.prefix}-vm"
  common_tags = {
    "Environment" = "tfpoc"
  }
}

# Using 2.61.0 cause 2.62.0 throws weird authorization errors for a while now
# https://discuss.hashicorp.com/t/azurerm-v2-62-0-now-requires-me-to-set-skip-provider-registration-to-true-when-v2-61-0-did-not/25082
terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "2.61.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Creating resource group.
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Creating virtual network for the VMs.
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags
}

# Creating subnet inside the virtual network.
resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Creating public IPs for the VMs.
resource "azurerm_public_ip" "pip" {
  count               = var.instance_count
  name                = "${local.vm_name}-${count.index}-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  tags                = local.common_tags
}

# Creating network interface cards for the VMs.
resource "azurerm_network_interface" "nic" {
  count               = var.instance_count
  name                = "${local.vm_name}-${count.index}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "nicconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[count.index].id
  }
}

# Creating network security group with a few basic rules - HTTPS, WinRm and RDP.
resource "azurerm_network_security_group" "nsg" {
  name                = "${azurerm_virtual_network.vnet.name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "HTTPS"  
    priority                   = 1000  
    direction                  = "Inbound"  
    access                     = "Allow"  
    protocol                   = "Tcp"  
    source_port_range          = "*"  
    destination_port_range     = "443"  
    source_address_prefix      = "*"  
    destination_address_prefix = "*"  
  }  
  security_rule {
    name                       = "winrm"  
    priority                   = 1010  
    direction                  = "Inbound"  
    access                     = "Allow"  
    protocol                   = "Tcp"  
    source_port_range          = "*"  
    destination_port_range     = "5985"  
    source_address_prefix      = "*"  
    destination_address_prefix = "*"  
  }  
  security_rule {
    name                       = "RDP"  
    priority                   = 110  
    direction                  = "Inbound"  
    access                     = "Allow"  
    protocol                   = "Tcp"  
    source_port_range          = "*"  
    destination_port_range     = "3389"  
    source_address_prefix      = "*"  
    destination_address_prefix = "*"  
  }
}

# Creating the VMs.
resource "azurerm_windows_virtual_machine" "vm" {
  count                 = var.instance_count
  name                  = "${local.vm_name}-${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  tags                  = local.common_tags

  os_disk {
    name                 = "${local.vm_name}-${count.index}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "21h1-ent-g2"
    version   = "latest"
  }

  # Using custom_data attribute to pass our post install script 
  # as a base64encoded string that will be then converted back to PS1 
  # and executed using FirstLogonCommands.xml.
  custom_data = filebase64("./files/postInstall.ps1")

  additional_unattend_content {
    setting = "FirstLogonCommands"
    content = file("./files/FirstLogonCommands.xml")
  }
}

data "azurerm_public_ip" "datapip" {
  name                = azurerm_public_ip.pip.name
  resource_group_name = azurerm_resource_group.rg.name
  depends_on          = [azurerm_virtual_machine.vm]
}

# Using output to output the IPs of the machines.
# You can then use terraform output > file.txt to get the outputs written to the file.
# There's an extra step which imports the IP as the data resource in order to get the output working
# cause otherwise it is empty - this is suggested by HashiCorp on their docs.
output "public_ip_address" {
  value = data.azurerm_public_ip.pip[count.index].ip_address
}


