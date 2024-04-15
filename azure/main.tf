provider "azurerm" {
  features {}
}

# Criar Grupo de Recursos
resource "azurerm_resource_group" "Grupo_de_recursos" {
  name     = "teste"
  location = "East US"
}

# Criar Conta de Armazenamento
resource "azurerm_storage_account" "Conta_de_armazenamento" {
  name                     = "apirodando"
  resource_group_name      = azurerm_resource_group.Grupo_de_recursos.name
  location                 = azurerm_resource_group.Grupo_de_recursos.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Criar VNET
resource "azurerm_virtual_network" "VNET" {
  name                = "VNET_Azure"
  address_space       = ["172.16.0.0/16"]
  location            = "East US"
  resource_group_name = azurerm_resource_group.Grupo_de_recursos.name
}

# Criar Subrede Pública
resource "azurerm_subnet" "Subrede_Publica" {
  name                 = "SubredePub"
  virtual_network_name = azurerm_virtual_network.VNET.name
  resource_group_name  = azurerm_resource_group.Grupo_de_recursos.name
  address_prefixes     = ["172.16.1.0/24"]
}

# Criar Subrede Privada
resource "azurerm_subnet" "Subrede_Privada" {
  name                 = "SubredePri"
  virtual_network_name = azurerm_virtual_network.VNET.name
  resource_group_name  = azurerm_resource_group.Grupo_de_recursos.name
  address_prefixes     = ["172.16.2.0/24"]
}

# Criar Grupo de Segurança
resource "azurerm_network_security_group" "Grupo_de_Seguranca_Linux" {
  name                = "Grupo_de_Segurança_Linux"
  location            = azurerm_resource_group.Grupo_de_recursos.location
  resource_group_name = azurerm_resource_group.Grupo_de_recursos.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Criar Grupo de Segurança
resource "azurerm_network_security_group" "Grupo_de_Seguranca_Windows" {
  name                = "Grupo_de_Segurança_Windows"
  location            = azurerm_resource_group.Grupo_de_recursos.location
  resource_group_name = azurerm_resource_group.Grupo_de_recursos.name

  security_rule {
    name                       = "RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Criar Interface de IP Público Linux
resource "azurerm_public_ip" "public_ip_linux" {
 name                = "public-ip-linux"
 location            = azurerm_resource_group.Grupo_de_recursos.location
 resource_group_name = azurerm_resource_group.Grupo_de_recursos.name
 allocation_method   = "Dynamic"
}

# Criar Interface de rede e Associar IP público na interface Linux
resource "azurerm_network_interface" "Interface_de_rede_Linux" {
 name                      = "Interface_de_rede_Linux"
 location                 = azurerm_resource_group.Grupo_de_recursos.location
 resource_group_name       = azurerm_resource_group.Grupo_de_recursos.name

 ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.Subrede_Publica.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip_linux.id
 }
}

# Criar Interface de IP Público Windows
resource "azurerm_public_ip" "public_ip_windows" {
 name                = "public-ip-windows"
 location            = azurerm_resource_group.Grupo_de_recursos.location
 resource_group_name = azurerm_resource_group.Grupo_de_recursos.name
 allocation_method   = "Dynamic"
}

# Criar Interface de rede e Associar IP público na interface Windows
resource "azurerm_network_interface" "Interface_de_rede_Windows" {
 name                      = "Interface_de_rede_Windows"
 location                 = azurerm_resource_group.Grupo_de_recursos.location
 resource_group_name       = azurerm_resource_group.Grupo_de_recursos.name

 ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.Subrede_Publica.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip_windows.id
 }
}

# Criar Maquina Virtual Linux
resource "azurerm_linux_virtual_machine" "linux" {
  name                = "linux"
  resource_group_name = azurerm_resource_group.Grupo_de_recursos.name
  location            = azurerm_resource_group.Grupo_de_recursos.location
  size                = "Standard_DS1_v2"
  disable_password_authentication = false

  admin_username = "adminuser"
  admin_password = "Senai@134@134"

  network_interface_ids = [
    azurerm_network_interface.Interface_de_rede_Linux.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

}

# Criar Maquina Virtual Windows
resource "azurerm_windows_virtual_machine" "windows" {
 name                = "Windows"
 resource_group_name = azurerm_resource_group.Grupo_de_recursos.name
 location            = azurerm_resource_group.Grupo_de_recursos.location
 size                = "Standard_DS1_v2"
 admin_username      = "adminuser"
 admin_password      = "Senai@134@134"

 network_interface_ids = [
    azurerm_network_interface.Interface_de_rede_Windows.id
 ]

 os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
 }

 source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
 }

 computer_name = "windowsvm"
 provision_vm_agent = true
 enable_automatic_updates = true
}

