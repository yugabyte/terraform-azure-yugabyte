terraform {
  required_version = ">= 0.12"
}

provider "azurerm" {
  version = "~>2.0"
  features {}
}

resource "azurerm_resource_group" "YugaByte-Group" {
  name     = var.resource_group == "null" ? var.cluster_name : var.resource_group
  location = var.region_name

  tags = {
    environment = "${var.prefix}${var.cluster_name}"
  }
}

# Create virtual network
resource "azurerm_virtual_network" "YugaByte-Network" {
  name                = "${var.prefix}${var.cluster_name}-VPC"
  address_space       = ["10.0.0.0/16"]
  location            = var.region_name
  resource_group_name = azurerm_resource_group.YugaByte-Group.name

  tags = {
    environment = "${var.prefix}${var.cluster_name}"
  }
}

# Create subnet
resource "azurerm_subnet" "YugaByte-SubNet" {
  count                = var.subnet_count
  name                 = "${var.prefix}${var.cluster_name}-Subnet-${format("%d", count.index + 1)}"
  resource_group_name  = azurerm_resource_group.YugaByte-Group.name
  virtual_network_name = azurerm_virtual_network.YugaByte-Network.name
  address_prefix       = "10.0.${count.index + 1}.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "YugaByte_Public_IP" {
  count               = var.node_count
  name                = "${var.prefix}${var.cluster_name}-Public-IP-${format("%d", count.index)}"
  location            = var.region_name
  resource_group_name = azurerm_resource_group.YugaByte-Group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [element(var.zone_list, count.index)]

  tags = {
    environment = "${var.prefix}${var.cluster_name}"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "YugaByte-SG" {
  name                = "${var.prefix}${var.cluster_name}-SG"
  location            = var.region_name
  resource_group_name = azurerm_resource_group.YugaByte-Group.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "9000", "7000", "6379", "9042", "5433", "7100", "9100"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "${var.prefix}${var.cluster_name}"
  }
}

resource "azurerm_subnet_network_security_group_association" "YugaByte-SG-Association" {
  count                     = var.node_count
  subnet_id                 = element(azurerm_subnet.YugaByte-SubNet.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.YugaByte-SG.id
}

# Create network interface
resource "azurerm_network_interface" "YugaByte-NIC" {
  count               = var.node_count
  name                = "${var.prefix}${var.cluster_name}-NIC-${format("%d", count.index + 1)}"
  location            = var.region_name
  resource_group_name = azurerm_resource_group.YugaByte-Group.name

  ip_configuration {
    name                          = "${var.prefix}${var.cluster_name}-NicConfiguration"
    subnet_id                     = element(azurerm_subnet.YugaByte-SubNet.*.id, count.index)
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.YugaByte_Public_IP.*.id, count.index)
  }

  tags = {
    environment = "${var.prefix}${var.cluster_name}"
  }
}

resource "azurerm_network_interface_security_group_association" "YugaByte-NIC-SG-Association" {
  count                     = var.node_count
  network_interface_id      = element(azurerm_network_interface.YugaByte-NIC.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.YugaByte-SG.id
}

# Create virtual machine
resource "azurerm_virtual_machine" "YugaByte-Node" {
  count                 = var.node_count
  name                  = "${var.prefix}${var.cluster_name}-node-${format("%d", count.index + 1)}"
  location              = var.region_name
  resource_group_name   = azurerm_resource_group.YugaByte-Group.name
  network_interface_ids = [element(azurerm_network_interface.YugaByte-NIC.*.id, count.index)]
  vm_size               = var.vm-size
  zones                 = [element(var.zone_list, count.index)]
  depends_on            = [azurerm_network_interface_security_group_association.YugaByte-NIC-SG-Association]

  storage_os_disk {
    name              = "${var.prefix}${var.cluster_name}-disk-n${format("%d", count.index + 1)}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = var.disk_size
  }

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.prefix}${var.cluster_name}${format("%d", count.index + 1)}"
    admin_username = var.ssh_user
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.ssh_user}/.ssh/authorized_keys"
      key_data = file(var.ssh_public_key)
    }
  }

  tags = {
    environment = "${var.prefix}${var.cluster_name}"
  }

  provisioner "file" {
    source      = "${path.module}/utilities/scripts/install_software.sh"
    destination = "/home/${var.ssh_user}/install_software.sh"
    connection {
      type = "ssh"
      user = var.ssh_user
      host = element(
        azurerm_public_ip.YugaByte_Public_IP.*.ip_address,
        count.index,
      )
      private_key = file(var.ssh_private_key)
    }
  }

  provisioner "file" {
    source      = "${path.module}/utilities/scripts/create_universe.sh"
    destination = "/home/${var.ssh_user}/create_universe.sh"
    connection {
      type = "ssh"
      user = var.ssh_user
      host = element(
        azurerm_public_ip.YugaByte_Public_IP.*.ip_address,
        count.index,
      )
      private_key = file(var.ssh_private_key)
    }
  }

  provisioner "file" {
    source      = "${path.module}/utilities/scripts/start_master.sh"
    destination = "/home/${var.ssh_user}/start_master.sh"
    connection {
      type = "ssh"
      user = var.ssh_user
      host = element(
        azurerm_public_ip.YugaByte_Public_IP.*.ip_address,
        count.index,
      )
      private_key = file(var.ssh_private_key)
    }
  }

  provisioner "file" {
    source      = "${path.module}/utilities/scripts/start_tserver.sh"
    destination = "/home/${var.ssh_user}/start_tserver.sh"
    connection {
      type = "ssh"
      user = var.ssh_user
      host = element(
        azurerm_public_ip.YugaByte_Public_IP.*.ip_address,
        count.index,
      )
      private_key = file(var.ssh_private_key)
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.ssh_user}/install_software.sh",
      "chmod +x /home/${var.ssh_user}/create_universe.sh",
      "chmod +x /home/${var.ssh_user}/start_tserver.sh",
      "chmod +x /home/${var.ssh_user}/start_master.sh",
      "/home/${var.ssh_user}/install_software.sh '${var.yb_version}'",
    ]
    connection {
      type = "ssh"
      user = var.ssh_user
      host = element(
        azurerm_public_ip.YugaByte_Public_IP.*.ip_address,
        count.index,
      )
      private_key = file(var.ssh_private_key)
    }
  }
}

locals {
  depends_on = [azurerm_virtual_machine.YugaByte-Node]
  ssh_ip_list = var.use_public_ip_for_ssh == "true" ? join(" ", azurerm_public_ip.YugaByte_Public_IP.*.ip_address) : join(
    " ",
    azurerm_network_interface.YugaByte-NIC.*.private_ip_address,
  )
  config_ip_list = join(
    " ",
    azurerm_network_interface.YugaByte-NIC.*.private_ip_address,
  )
  zone = join(" ", azurerm_virtual_machine.YugaByte-Node.*.zones.0)
}

resource "null_resource" "create_yugabyte_universe" {
  depends_on = [azurerm_virtual_machine.YugaByte-Node]

  provisioner "local-exec" {
    command = "${path.module}/utilities/scripts/create_universe.sh 'Azure' '${var.region_name}' ${var.replication_factor} '${local.config_ip_list}' '${local.ssh_ip_list}' '${local.zone}' '${var.ssh_user}' ${var.ssh_private_key}"
  }
}
