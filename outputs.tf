output "public_vm_ip" {
  description = "パブリック VM のグローバル IP アドレス（SSH 接続時に使用）"
  value       = azurerm_public_ip.pip_public_vm.ip_address
}

output "public_vm_private_ip" {
  description = "パブリック VM のプライベート IP アドレス"
  value       = azurerm_network_interface.nic_public_vm.private_ip_address
}

output "private_vm_private_ip" {
  description = "プライベート VM のプライベート IP アドレス（踏み台経由 SSH 時に使用）"
  value       = azurerm_network_interface.nic_private_vm.private_ip_address
}
