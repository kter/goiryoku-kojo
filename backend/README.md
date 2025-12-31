# 語彙力向上 Backend

語彙力トレーニングアプリのバックエンドシステムです。

## 構成

```
backend/
├── functions/
│   ├── shared/           # 共通ライブラリ
│   │   ├── firestore_client.py
│   │   └── gemini_client.py
│   ├── get_words/        # API関数
│   │   └── main.py
│   └── generate_words/   # バッチ生成関数
│       └── main.py
├── infra/                # Terraform設定
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── scripts/              # CLIスクリプト
│   └── generate_initial_words.py
└── tests/                # ユニットテスト
```

## セットアップ

### 1. GCP認証
```bash
gcloud auth application-default login
```

### 2. Terraformデプロイ
```bash
cd backend/infra
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars を編集して project_id を設定
terraform init
terraform plan
terraform apply
```

### 3. 初期データ生成
```bash
cd backend
python scripts/generate_initial_words.py --days 30
```

## API

### GET /get-words

お題を取得するAPI。

**パラメータ:**
- `days` (optional): 取得日数 (1-30, default: 30)

**レスポンス:**
```json
{
  "success": true,
  "count": 30,
  "words": [
    {"date": "2024-01-01", "word": "概念", "reading": "がいねん"}
  ],
  "date_range": {
    "start": "2024-01-01",
    "end": "2024-01-30"
  }
}
```

## テスト

```bash
pip install -r requirements-dev.txt
python -m pytest tests/ -v
```
