# Remote state backend configuration for prod environment
# Fill in the resource group, storage account, and container for your TF state.
# This file is intended for local usage. In CI, values can be overridden with -backend-config flags.
resource_group_name  = "<tfstate-rg>"
storage_account_name = "<tfstate_sa>"
container_name       = "<tfstate_container>"
key                  = "tripradar-prod.tfstate"
