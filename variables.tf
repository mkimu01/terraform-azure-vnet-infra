variable "resource_group_name" {
  type        = string
  description = "リソースグループ名"
  default     = "rg-portfolio-dev"
}

variable "location" {
  type        = string
  description = "Azure リージョン"
  default     = "japaneast"
}

variable "vnet_name" {
  type        = string
  description = "VNet 名"
  default     = "vnet-portfolio"
}

variable "admin_username" {
  type        = string
  description = "VM の管理者ユーザー名"
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  type        = string
  description = "SSH 公開鍵のローカルパス（terraform.tfvars で指定）"
  # ⚠️ terraform.tfvars に記載し、Git に含めないこと
}

variable "allowed_ssh_ip" {
  type        = string
  description = "SSH 許可元 IP（CIDR 形式、terraform.tfvars で指定）"
  # ⚠️ 自分のグローバル IP を /32 で指定すること。0.0.0.0/0 は厳禁
  # ⚠️ terraform.tfvars に記載し、Git に含めないこと
}
