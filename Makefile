# Makefile for 語彙力向上 (Goiryoku Kojo)

.PHONY: help setup run run-ios run-android build-ios build-android build-apk clean analyze test gen-l10n
.PHONY: backend-install backend-test terraform-init terraform-validate terraform-plan terraform-apply
.PHONY: generate-words generate-words-dry dev-get-words dev-generate-words backend-clean

MOBILE_DIR = mobile
BACKEND_DIR = backend

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ======================
# Mobile (Flutter)
# ======================

# Setup
setup: ## Install Flutter dependencies
	cd $(MOBILE_DIR) && flutter pub get

# Development
run: ## Run the app on connected device
	cd $(MOBILE_DIR) && flutter run

run-ios: ## Run the app on iOS simulator
	cd $(MOBILE_DIR) && flutter run -d ios

run-android: ## Run the app on Android emulator
	cd $(MOBILE_DIR) && flutter run -d android

# Build
build-ios: ## Build iOS release
	cd $(MOBILE_DIR) && flutter build ios --release

build-android: ## Build Android release (AAB)
	cd $(MOBILE_DIR) && flutter build appbundle --release

build-apk: ## Build Android APK
	cd $(MOBILE_DIR) && flutter build apk --release

# Code Quality
analyze: ## Run Flutter analyzer
	cd $(MOBILE_DIR) && flutter analyze

test: ## Run Flutter tests
	cd $(MOBILE_DIR) && flutter test

format: ## Format Dart code
	cd $(MOBILE_DIR) && dart format lib test

# Code Generation
gen-l10n: ## Generate localization files
	cd $(MOBILE_DIR) && flutter gen-l10n

# Maintenance
clean: ## Clean Flutter build artifacts
	cd $(MOBILE_DIR) && flutter clean

upgrade: ## Upgrade Flutter dependencies
	cd $(MOBILE_DIR) && flutter pub upgrade

outdated: ## Check for outdated dependencies
	cd $(MOBILE_DIR) && flutter pub outdated

# ======================
# Backend (Python/GCP)
# ======================

# Setup
backend-install: ## Install backend dependencies
	pip install -r $(BACKEND_DIR)/requirements-dev.txt
	pip install -r $(BACKEND_DIR)/functions/shared/requirements.txt

# Testing
backend-test: ## Run backend unit tests
	cd $(BACKEND_DIR) && python -m pytest tests/ -v

backend-test-verbose: ## Run backend tests with verbose output
	cd $(BACKEND_DIR) && python -m pytest tests/ -v --tb=long

# Terraform
terraform-init: ## Initialize Terraform
	cd $(BACKEND_DIR)/infra && terraform init

terraform-validate: ## Validate Terraform configuration
	cd $(BACKEND_DIR)/infra && terraform validate

terraform-plan: ## Show Terraform execution plan
	cd $(BACKEND_DIR)/infra && terraform plan

terraform-apply: ## Apply Terraform configuration
	cd $(BACKEND_DIR)/infra && terraform apply

terraform-destroy: ## Destroy Terraform resources
	cd $(BACKEND_DIR)/infra && terraform destroy

# Data Generation
generate-words: ## Generate initial 30 days of words
	cd $(BACKEND_DIR) && python scripts/generate_initial_words.py --days 30

generate-words-dry: ## Dry run word generation (no save)
	cd $(BACKEND_DIR) && python scripts/generate_initial_words.py --days 30 --dry-run

generate-words-7: ## Generate 7 days of words
	cd $(BACKEND_DIR) && python scripts/generate_initial_words.py --days 7

# Local Development
dev-get-words: ## Run get_words function locally (port 8080)
	cd $(BACKEND_DIR)/functions/get_words && pip install functions-framework && functions-framework --target=get_words --debug --port=8080

dev-generate-words: ## Run generate_words function locally (port 8081)
	cd $(BACKEND_DIR)/functions/generate_words && pip install functions-framework && functions-framework --target=generate_words --debug --port=8081

# Cleanup
backend-clean: ## Clean backend temporary files
	rm -rf $(BACKEND_DIR)/infra/tmp
	rm -rf $(BACKEND_DIR)/infra/.terraform
	find $(BACKEND_DIR) -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find $(BACKEND_DIR) -type f -name "*.pyc" -delete 2>/dev/null || true

