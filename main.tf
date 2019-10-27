
# Configure the Microsoft Azure Provider
provider "azurerm" {

}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "TerraformResourceGroup"
    location = "eastus"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    tags = {
        environment = "Terraform Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.myterraformgroup.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.myterraformgroup.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "ssh-access" {
    name                = "myNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name
    
  security_rule {
name = "AllowSSH"
priority = 100
direction = "Inbound"
access         = "Allow"
protocol = "Tcp"
source_port_range       = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
name = "AllowHTTP"
priority= 200
direction= "Inbound"
access = "Allow"
protocol = "Tcp"
source_port_range       = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
name = "HTTP3200"
priority= 300
direction= "Inbound"
access = "Allow"
protocol = "Tcp"
source_port_range       = "*"
    destination_port_range     = "3200"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    name                      = "myNIC"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.myterraformgroup.name
    network_security_group_id = azurerm_network_security_group.ssh-access.id

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.myterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.myterraformgroup.name
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.myterraformgroup.name
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "nginx-1"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.myterraformgroup.name
    network_interface_ids = [azurerm_network_interface.myterraformnic.id]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "nginx1"
        admin_username = "az-user"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/az-user/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIdoA+q/0PrRdl9mqlEzAFTDo8Zjse1zBCWce5HXsbxYtEkuUi182PNK/pdxgBA8Tijmi45Miu9bJ+xH9UGtBrXMcJtZ9OAe88demuhiRHXzFzgzPIfB+gMdzWt09B6+/PllZS7IfqBJVaX8PZpKKQE7QLvkkXr07ETNE2SfD3vPaPzFrMVgoZlqmdoSHVyG+mxyiV3X/Lt9gPYdA3XxI6onVmXM3ggQTneFGoY/bVuWZxOohh6GvfjiTJBrkK19loRMUHMUHsHFI4z7C5fGlMR91F/SuquwPfG4DT6qeC2PYoq3dTxY5NQscz8EmFrX+bz20Ss/Xt2DfTkhb8fyip"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_virtual_machine_extension" "script" {
  name                 = "nginx-1"
  location             = "eastus"
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  virtual_machine_name = azurerm_virtual_machine.myterraformvm.name
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
  {
  "fileUris": ["https://mail.systemrg.com/terraform-nginx/userdata.sh"],
    "commandToExecute": "/bin/bash userdata.sh"
  }
SETTINGS

  tags = {
    environment = "Terraform Demo"
  }

}

