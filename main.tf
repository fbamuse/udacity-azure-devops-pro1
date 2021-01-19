provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x.
    # If you're using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    subscription_id = var.subscription_id
    client_id       = var.client_id
    client_secret   = var.client_secret
    tenant_id       = var.tenant_id

    features {}
}

#variable "region" {default="East US"}
#variable  num{}
#variable "prefix"{}
#variable "userid"{}
#variable "passwd"{}

resource "azurerm_resource_group" "uda_group" {
    name     = "RG-${var.prefix}"
    location = var.region

    tags = {
        label = "Terraform Demo-${var.prefix}"
    }
}

#Vnet
resource "azurerm_virtual_network" "uda_network" {
    name                = "vnet-${var.prefix}"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.uda_group.location
    resource_group_name = azurerm_resource_group.uda_group.name

    tags = {
        label = "Terraform Demo-${var.prefix}"
    }
}
resource "azurerm_subnet" "uda_subnet" {
    name                 = "subnet-${var.prefix}"
    resource_group_name  = azurerm_resource_group.uda_group.name
    virtual_network_name = azurerm_virtual_network.uda_network.name
    address_prefixes       = ["10.0.0.0/24"]
}


#load balancer

resource "azurerm_lb" "uda_lb" {
    name                = "loadBalancer-${var.prefix}"
    location            = azurerm_resource_group.uda_group.location
    resource_group_name = azurerm_resource_group.uda_group.name

    frontend_ip_configuration {
        name                 = "publicIPAddress"
        public_ip_address_id = azurerm_public_ip.uda_publicip.id
    }

    tags = {
        label = "Terraform Demo-${var.prefix}"
    }

}
resource "azurerm_public_ip" "uda_publicip" {
    name                         = "publicIPforLB-${var.prefix}"
    location                     = azurerm_resource_group.uda_group.location
    resource_group_name          = azurerm_resource_group.uda_group.name
    allocation_method            = "Static"

    tags = {
        label = "Terraform Demo-${var.prefix}"
    }
}

#backend pool
resource "azurerm_lb_backend_address_pool" "main" {
    resource_group_name = azurerm_resource_group.uda_group.name
    loadbalancer_id     = azurerm_lb.uda_lb.id
    name                = "BackEndAddressPool"
}
resource "azurerm_network_interface_backend_address_pool_association" "main" {
    count                   = var.num
    network_interface_id    = element(azurerm_network_interface.uda_netIF.*.id, count.index)
    ip_configuration_name   = "${var.prefix}-ipconfig"
    backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}
#Load balancing rules
resource "azurerm_lb_rule" "main" {
    name                           = "lbRule-${var.prefix}"
    resource_group_name            = azurerm_resource_group.uda_group.name
    loadbalancer_id                = azurerm_lb.uda_lb.id
    protocol                       = "Tcp"
    frontend_port                  = 80
    backend_port                   = 80
    frontend_ip_configuration_name = azurerm_lb.uda_lb.frontend_ip_configuration[0].name
    backend_address_pool_id        = azurerm_lb_backend_address_pool.main.id
    probe_id                       = azurerm_lb_probe.main.id
}
#Health probes
resource "azurerm_lb_probe" "main" {
    name                = "http-probe-${var.prefix}"
    resource_group_name = azurerm_resource_group.uda_group.name
    loadbalancer_id     = azurerm_lb.uda_lb.id
    port                = 80
}

#Network Security Group

resource "azurerm_network_security_group" "uda_sg" {
    name                = "SG-${var.prefix}"
    location            = azurerm_resource_group.uda_group.location
    resource_group_name = azurerm_resource_group.uda_group.name

    security_rule {
        name = "allow-80"
        priority = 100
        direction = "Inbound"
        access = "Allow"
        protocol = "TCP"
        source_port_range = "*"
        destination_port_range = 80
        source_address_prefix       = "*"
        destination_address_prefix  = "*"
   
    }

    security_rule  {
        name                       = "deny-internet"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "TCP"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        label = "Terraform Demo-${var.prefix}"
    }
}

resource "azurerm_network_interface" "uda_netIF" {
    count                       = var.num
    name                        = "myNIC-${var.prefix}-${count.index}"
    location                    = azurerm_resource_group.uda_group.location
    resource_group_name         = azurerm_resource_group.uda_group.name

    ip_configuration {
        name                          = "${var.prefix}-ipconfig"
        subnet_id                     = azurerm_subnet.uda_subnet.id
        private_ip_address_allocation = "Dynamic"
    }

    tags = {
        label = "Terraform Demo-${var.prefix}"
    }
}


resource "azurerm_managed_disk" "uda_disk" {
    count                = var.num
    name                 = "datadisk_existing-${var.prefix}-${count.index}"
    location             = azurerm_resource_group.uda_group.location
    resource_group_name  = azurerm_resource_group.uda_group.name
    storage_account_type = "Standard_LRS"
    create_option        = "Empty"
    disk_size_gb         = "1"

    tags = {
        label = "Terraform Demo-${var.prefix}"
    }

}

resource "azurerm_availability_set" "uda_avaset" {
    name                         = "avset-${var.prefix}"
    location                     = azurerm_resource_group.uda_group.location
    resource_group_name          = azurerm_resource_group.uda_group.name
    platform_fault_domain_count  = var.num
    platform_update_domain_count = var.num
    managed                      = true
    tags = {
        label = "Terraform Demo-${var.prefix}"
    }

}

data "azurerm_resource_group" "image" {
    name = "uda1"
}

data "azurerm_image" "image" {
    name                = "PackerImage"
    resource_group_name = data.azurerm_resource_group.image.name
}

resource "azurerm_virtual_machine" "uda_vm" {
    count                 = var.num
    name                  = "acctvm-${var.prefix}-${count.index}"
    location              = azurerm_resource_group.uda_group.location
    availability_set_id   = azurerm_availability_set.uda_avaset.id
    resource_group_name   = azurerm_resource_group.uda_group.name
    network_interface_ids = [element(azurerm_network_interface.uda_netIF.*.id, count.index)]
    vm_size               = "Standard_DS1_v2"
    

    storage_image_reference {
        id = data.azurerm_image.image.id
    }

    storage_os_disk {
        name              = "myosdisk${count.index}"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_data_disk {
        name            = element(azurerm_managed_disk.uda_disk.*.name, count.index)
        managed_disk_id = element(azurerm_managed_disk.uda_disk.*.id, count.index)
        create_option   = "Attach"
        lun             = 1
        disk_size_gb    = element(azurerm_managed_disk.uda_disk.*.disk_size_gb, count.index)
    }
    os_profile {
        computer_name  = "DHDIAHDAWDGLASD-${var.prefix}-${count.index}"
        admin_username = var.userid
        admin_password = var.passwd
    }
    os_profile_linux_config {
        disable_password_authentication = false
    }

    tags = {
        label = "Terraform Demo-${var.prefix}"
    }
}