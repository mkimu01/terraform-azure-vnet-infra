# Azure VNet Terraform ポートフォリオ

Azure Virtual Network（パブリック・プライベートサブネット）を Terraform で構築・管理するポートフォリオプロジェクトです。

---

## システム構成

```
Azure Virtual Network (10.0.0.0/16)
├── パブリックサブネット (10.0.1.0/27)
│   └── Public VM (Ubuntu 22.04)
│       ├── パブリック IP あり
│       └── NSG: SSH / HTTP / HTTPS を許可
└── プライベートサブネット (10.0.2.0/27)
    └── Private VM (Ubuntu 22.04)
        ├── パブリック IP なし
        └── NSG: パブリックサブネットからの通信のみ許可
             インターネット Outbound は拒否
```

### 検証した通信シナリオ

| # | 通信 | 結果 |
|---|------|------|
| 1 | Local PC → Public VM（SSH） | 合格 |
| 2 | Public VM → Internet（curl） | 合格 |
| 3 | Public VM → Private VM（SSH 踏み台） | 合格 |
| 4 | Public VM → Private VM（ping） | 合格 |
| 5 | Private VM → Internet（curl） | 合格（タイムアウト = 拒否が成功） |
| 6 | Local PC → Private VM（SSH 直接） | 合格（接続不可 = 拒否が成功） |

---

## ファイル構成

```
terraform/
├── main.tf           # プロバイダー・リソースグループの定義
├── vnet.tf           # VNet・サブネット・NSG・ルールの定義
├── vm.tf             # VM・NIC・パブリック IP の定義
├── variables.tf      # 変数の型・説明・デフォルト値
├── outputs.tf        # デプロイ後の出力（IP アドレスなど）
├── versions.tf       # Terraform・プロバイダーのバージョン固定
├── .terraform.lock.hcl  # プロバイダーバージョンのロックファイル
└── .gitignore        # 秘匿情報・不要ファイルの除外設定
```

> `terraform.tfvars`（変数実値）・`*.tfstate`（状態ファイル）は秘匿情報を含むため `.gitignore` で除外しています。

---

## 使用技術

| 技術 | バージョン |
|------|-----------|
| Terraform | >= 1.14.6 |
| Azure Provider (azurerm) | ~> 4.63 |
| Microsoft Azure | - |
| Ubuntu | 22.04 LTS |
