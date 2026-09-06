SHELL := /bin/bash

ENV ?= dev
TF_VARS_FILE := envs/$(ENV)/terraform.tfvars
TF_BACKEND_FILE := envs/$(ENV)/backend.hcl

.PHONY: help bootstrap plan apply destroy clean fmt validate

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

fmt: ## Format and check all Terraform files
	terraform fmt -recursive -check

validate: ## Validate Terraform configuration for $(ENV)
	terraform init -input=false -backend-config=$(TF_BACKEND_FILE)
	terraform validate

bootstrap: ## Create state buckets, lock table and GitHub OIDC role (run once)
	cd bootstrap && terraform init && terraform plan -out=bootstrap.plan && terraform apply bootstrap.plan

plan: ## Run terraform plan for $(ENV)
	terraform init -input=false -backend-config=$(TF_BACKEND_FILE)
	terraform plan -input=false -var-file=$(TF_VARS_FILE) -out=tfplan

apply: ## Apply terraform plan for $(ENV)
	terraform init -input=false -backend-config=$(TF_BACKEND_FILE)
	terraform apply -input=false -auto-approve tfplan

destroy: ## Destroy infrastructure for $(ENV)
	terraform init -input=false -backend-config=$(TF_BACKEND_FILE)
	terraform destroy -input=false -auto-approve -var-file=$(TF_VARS_FILE)

clean: ## Remove local state and plan files
	rm -rf .terraform tfplan
	find . -name '*.tfstate*' -delete