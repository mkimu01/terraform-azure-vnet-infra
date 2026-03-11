# ================================================================
# Virtual Network
# ================================================================

resource "azurerm_virtual_network" "vnet_main" {
  name                = var.vnet_name
  location            = azurerm_resource_group.rg_main.location
  resource_group_name = azurerm_resource_group.rg_main.name
  address_space       = ["10.0.0.0/16"]
}

# ================================================================
# Subnets
# ================================================================

resource "azurerm_subnet" "subnet_public" {
  name                 = "subnet-public"
  resource_group_name  = azurerm_resource_group.rg_main.name
  virtual_network_name = azurerm_virtual_network.vnet_main.name
  address_prefixes     = ["10.0.1.0/27"]
}

resource "azurerm_subnet" "subnet_private" {
  name                 = "subnet-private"
  resource_group_name  = azurerm_resource_group.rg_main.name
  virtual_network_name = azurerm_virtual_network.vnet_main.name
  address_prefixes     = ["10.0.2.0/27"]
}

# ================================================================
# NSG - パブリックサブネット用
# ================================================================

resource "azurerm_network_security_group" "nsg_public" {
  name                = "nsg-public"
  location            = azurerm_resource_group.rg_main.location
  resource_group_name = azurerm_resource_group.rg_main.name

  # SSH: 自分の固定 IP からのみ許可
  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_ip
    destination_address_prefix = "*"
  }

  # 全拒否（明示化）
  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ================================================================
# NSG - プライベートサブネット用
# ================================================================

resource "azurerm_network_security_group" "nsg_private" {
  name                = "nsg-private"
  location            = azurerm_resource_group.rg_main.location
  resource_group_name = azurerm_resource_group.rg_main.name

  # SSH: パブリックサブネット（踏み台）からのみ許可
  security_rule {
    name                       = "allow-ssh-from-public"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.1.0/27"
    destination_address_prefix = "*"
  }

  # ping: 疎通確認用（パブリックサブネットからのみ）
  security_rule {
    name                       = "allow-icmp-from-public"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.1.0/27"
    destination_address_prefix = "*"
  }

  # 全拒否（明示化）
  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # インターネット直接接続を拒否（検証シナリオの核心ルール）
  security_rule {
    name                       = "deny-internet-outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  # VNet 内通信は許可
  security_rule {
    name                       = "allow-vnet-outbound"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }
}

# ================================================================
# NSG とサブネットの紐付け
# ================================================================

resource "azurerm_subnet_network_security_group_association" "nsg_assoc_public" {
  subnet_id                 = azurerm_subnet.subnet_public.id
  network_security_group_id = azurerm_network_security_group.nsg_public.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc_private" {
  subnet_id                 = azurerm_subnet.subnet_private.id
  network_security_group_id = azurerm_network_security_group.nsg_private.id
}

# ================================================================
# Public IP
# ================================================================

# Basic SKU は 2025/9/30 に廃止済みのため Standard/Static を使用
# Static のため IP は固定されるが、terraform destroy で解放される
resource "azurerm_public_ip" "pip_public_vm" {
  name                = "pip-public-vm"
  location            = azurerm_resource_group.rg_main.location
  resource_group_name = azurerm_resource_group.rg_main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# ================================================================
# Network Interfaces
# ================================================================

resource "azurerm_network_interface" "nic_public_vm" {
  name                = "nic-public-vm"
  location            = azurerm_resource_group.rg_main.location
  resource_group_name = azurerm_resource_group.rg_main.name

  ip_configuration {
    name                          = "ipconfig-public"
    subnet_id                     = azurerm_subnet.subnet_public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_public_vm.id
  }
}

resource "azurerm_network_interface" "nic_private_vm" {
  name                = "nic-private-vm"
  location            = azurerm_resource_group.rg_main.location
  resource_group_name = azurerm_resource_group.rg_main.name

  ip_configuration {
    name                          = "ipconfig-private"
    subnet_id                     = azurerm_subnet.subnet_private.id
    private_ip_address_allocation = "Dynamic"
    # グローバル IP なし（プライベート VM はインターネット直接接続不可）
  }
}
