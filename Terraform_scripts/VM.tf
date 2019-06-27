# Configure the Microsoft Azure Provider
provider "azurerm" {
version = "=1.30.1"
}

variable "prefix" {
	default = "Terraform"
}


# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "main" {
    name     = "${var.prefix}--resources"
    location = "uksouth"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "network" {
    name                = "${var.prefix}--Vnet"
    address_space       = ["10.0.0.0/16"]
    location            = "${azurerm_resource_group.main.location}"
    resource_group_name = "${azurerm_resource_group.main.name}"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "subnet" {
    name                 = "${var.prefix}--Subnet"
    resource_group_name  = "${azurerm_resource_group.main.name}"
    virtual_network_name = "${azurerm_virtual_network.network.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "publicip" {
    name                         = "${var.prefix}--PublicIP"
    location                     = "${azurerm_resource_group.main.location}"
    resource_group_name          = "${azurerm_resource_group.main.name}"
    allocation_method            = "Dynamic"
    domain_name_label		 = "azureuser-${formatdate("DDMMYYhhmmss", timestamp())}"	
    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_public_ip" "publicip2" {
    name                         = "${var.prefix}--PublicIP2"
    location                     = "${azurerm_resource_group.main.location}"
    resource_group_name          = "${azurerm_resource_group.main.name}"
    allocation_method            = "Dynamic"
    domain_name_label            = "azureuser2-${formatdate("DDMMYYhhmmss", timestamp())}"  
    }


# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
    name                = "${var.prefix}--NSG"
    location            = "${azurerm_resource_group.main.location}"
    resource_group_name = "${azurerm_resource_group.main.name}"
    
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

    security_rule {
        name                       = "Jenkins"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8080"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "HTTPS"
        priority                   = 1003
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }


    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "nic1" {
    name                      = "${var.prefix}--NIC1"
    location                  = "${azurerm_resource_group.main.location}"
    resource_group_name       = "${azurerm_resource_group.main.name}"
    network_security_group_id = "${azurerm_network_security_group.nsg.id}"

    ip_configuration {
        name                          = "${var.prefix}--Configuration"
        subnet_id                     = "${azurerm_subnet.subnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.publicip.id}"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_network_interface" "nic2" {
    name                      = "${var.prefix}--NIC2"
    location                  = "${azurerm_resource_group.main.location}"
    resource_group_name       = "${azurerm_resource_group.main.name}"
    network_security_group_id = "${azurerm_network_security_group.nsg.id}"

    ip_configuration {
        name                          = "${var.prefix}--Configuration"
        subnet_id                     = "${azurerm_subnet.subnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.publicip2.id}"
    }

    tags = {
        environment = "Terraform Demo"
    }
}


# Generate random text for a unique storage account name
#resource "random_id" "randomId" {
#   keepers = {
# Generate a new ID only when a new resource group is defined
#        resource_group = "${azurerm_resource_group.myterraformgroup.name}"
#    }
#   
#    byte_length = 8
#}

# Create storage account for boot diagnostics
#resource "azurerm_storage_account" "mystorageaccount" {
#    name                        = "diag${random_id.randomId.hex}"
#    resource_group_name         = "${azurerm_resource_group.myterraformgroup.n#ame}"
#    location                    = "eastus"
#    account_tier                = "Standard"
#    account_replication_type    = "LRS"
#
#    tags = {
#        environment = "Terraform Demo"
#    }
#}

# Create virtual machine
resource "azurerm_virtual_machine" "vm1" {
    name                  = "${var.prefix}--VM1"
    location              = "${azurerm_resource_group.main.location}"
    resource_group_name   = "${azurerm_resource_group.main.name}"
    network_interface_ids = ["${azurerm_network_interface.nic1.id}"]
    vm_size               = "Standard_B1ms"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "myvm1"
        admin_username = "azureuser"
	admin_password = "password123!"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "${file("/home/david/.ssh/id_rsa.pub")}"
        }
    }

#    boot_diagnostics {
#        enabled = "true"
#        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
#    }

    tags = {
        environment = "Terraform Demo"
    }

provisioner "remote-exec" {
inline = ["sudo apt update", "sudo apt install -y jq", "git clone https://github.com/DWONeill18/devOps_jenkinsSetup.git"]
  connection {
type = "ssh"
user = "azureuser"
private_key = "${file("/home/david/.ssh/id_rsa")}"
host = "${azurerm_public_ip.publicip.fqdn}"
  }
  }
}		

