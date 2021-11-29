# ---------------------------------------------------------------------------------------------------------------------
# Local Variables
# ---------------------------------------------------------------------------------------------------------------------
locals {
  account_tier             = (var.account_kind == "FileStorage" ? "Premium" : (var.account_kind == "BlockBlobStorage" ? "Premium" : split("_", var.skuname)[0]))
	account_replication_type = (local.account_tier == "Premium" ? "LRS" : split("_", var.skuname)[1])
}
# ---------------------------------------------------------------------------------------------------------------------
# Azure Resource Group Creation or selection - Default is "false"
# ---------------------------------------------------------------------------------------------------------------------
data "azurerm_resource_group" "this" {
  count = var.create_resource_group == false ? 1 : 0
  name  = var.resource_group_name
}

resource "azurerm_resource_group" "this" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# ---------------------------------------------------------------------------------------------------------------------
# Creating Azure Storage Account
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_storage_account" "this" {
  name                      = substr(lower(replace(var.storage_account_name, "-", "")), 0, 24)
  resource_group_name       = var.resource_group_name
  location                  = var.location
  account_kind              = var.account_kind
  account_tier              = local.account_tier
  account_replication_type  = local.account_replication_type
  enable_https_traffic_only = true # Always enable https traffic only
  min_tls_version           = "TLS1_2" # Always use latest tls version
  allow_blob_public_access  = false # Always block public access

  tags                      = var.tags

  identity {
    type         = var.identity_ids != null ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = var.identity_ids
  }

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = var.virtual_network_subnet_ids
    ip_rules                   = [for r in var.ip_rules : replace(r, "/32", "")]
    bypass                     = ["Logging", "Metrics", "AzureServices"]
  }

  ## Discuss blob properties with team
  # blob_properties {
  #   delete_retention_policy {
  #     days = var.blob_soft_delete_retention_days
  #   }
  #   container_delete_retention_policy {
  #     days = var.container_soft_delete_retention_days
  #   }
  #   versioning_enabled = var.enable_versioning
  #   last_access_time_enabled = var.last_access_time_enabled
  #   change_feed_enabled = var.change_feed_enabled
  # }
}

# ---------------------------------------------------------------------------------------------------------------------
# Storage Advanced Threat Protection 
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_advanced_threat_protection" "this" {
  target_resource_id = azurerm_storage_account.this.id
  enabled            = true
}

# ---------------------------------------------------------------------------------------------------------------------
# Creating Storage Container(s)
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_storage_container" "this" {
  for_each              = toset(var.containers_list)
  name                  = each.value
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}