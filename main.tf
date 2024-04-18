#Refer to a resource group
data "azurerm_resource_group" "Global" {
  name = "Global"
}

#Refer to existing virtual networks
data "azurerm_virtual_network" "main" {
  name                = "AUOVNet"
  resource_group_name = data.azurerm_resource_group.Global.name
}

#Refer to a subnet
data "azurerm_subnet" "internal" {
  name                 = "AUO-AzureOAServerFarm"
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.Global.name
}

resource "azurerm_resource_group" "Terraform-CICD" {
  name     = "Terraform-CICD"
  location = var.location
}

#Create network_interface for VM (No public IP)
resource "azurerm_network_interface" "main" {
  name                = "main-nic"
  location            = azurerm_resource_group.Terraform-CICD.location
  resource_group_name = azurerm_resource_group.Terraform-CICD.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = data.azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_security_group" "appnsg" {
  name                = "app-nsg"
  location            = azurerm_resource_group.Terraform-CICD.location
  resource_group_name = azurerm_resource_group.Terraform-CICD.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.appnsg.id
}

resource "tls_private_key" "linuxkey" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "local_file" "linuxpemkey" {
  filename = "linuxkey.pem"
  content = tls_private_key.linuxkey.private_key_pem
  depends_on = [ tls_private_key.linuxkey ]
}

resource "azurerm_linux_virtual_machine" "Terraform-Test" {
  name                  = "myTerraform-test"
  location              = azurerm_resource_group.Terraform-CICD.location
  resource_group_name   = azurerm_resource_group.Terraform-CICD.name
  size                  = "Standard_DS1_v2"
  admin_username        = "azureuser"
  admin_ssh_key {
    username = "azureuser"
    public_key = tls_private_key.linuxkey.public_key_openssh
  }
  network_interface_ids = [azurerm_network_interface.main.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  tags = {
    environment = "staging"
  }
}
