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
  name                      = substr(lower(var.storage_account_name), 0, 24)
  resource_group_name       = var.resource_group_name
  location                  = var.location
  account_kind              = var.account_kind
  account_tier              = local.account_tier
  account_replication_type  = local.account_replication_type
  enable_https_traffic_only = true
  min_tls_version           = var.min_tls_version
  allow_blob_public_access  = var.enable_advanced_threat_protection == true ? true : false

  tags                      = var.tags

  identity {
    type         = var.identity_ids != null ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = var.identity_ids
  }

  blob_properties {
    delete_retention_policy {
      days = var.blob_soft_delete_retention_days
    }
    container_delete_retention_policy {
      days = var.container_soft_delete_retention_days
    }
    versioning_enabled = var.enable_versioning
    last_access_time_enabled = var.last_access_time_enabled
    change_feed_enabled = var.change_feed_enabled
  }

	queue_properties {
     logging {
        delete                = true
        read                  = true
        write                 = true
        version               = "1.0"
        retention_policy_days = 10
    }
  }

  dynamic "network_rules" {
    for_each = var.network_rules != null ? ["true"] : []
    content {
      default_action             = "Deny"
      bypass                     = var.network_rules.bypass
      ip_rules                   = var.network_rules.ip_rules
      virtual_network_subnet_ids = var.network_rules.subnet_ids
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Storage Advanced Threat Protection 
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_advanced_threat_protection" "this" {
  target_resource_id = azurerm_storage_account.this.id
  enabled            = var.enable_advanced_threat_protection
}

# ---------------------------------------------------------------------------------------------------------------------
# Creating Storage Container(s)
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_storage_container" "this" {
  count                 = length(var.containers_list)
  name                  = var.containers_list[count.index].name
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = var.containers_list[count.index].access_type
}

# ---------------------------------------------------------------------------------------------------------------------
# Creating Storage Fileshare(s)
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_storage_share" "this" {
  count                = length(var.file_shares)
  name                 = var.file_shares[count.index].name
  storage_account_name = azurerm_storage_account.this.name
  quota                = var.file_shares[count.index].quota
}

# ---------------------------------------------------------------------------------------------------------------------
# Creating Storage Table(s)
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_storage_table" "this" {
  count                = length(var.tables)
  name                 = var.tables[count.index]
  storage_account_name = azurerm_storage_account.this.name
}

# ---------------------------------------------------------------------------------------------------------------------
# Creating Storage Queue(s)
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_storage_queue" "this" {
  count                = length(var.queues)
  name                 = var.queues[count.index]
  storage_account_name = azurerm_storage_account.this.name
}

# ---------------------------------------------------------------------------------------------------------------------
# Creating Azure Storage Lifecyle Management Policy
# ---------------------------------------------------------------------------------------------------------------------
# resource "azurerm_storage_management_policy" "lcpolicy" {
#   count              = length(var.lifecycles) == 0 ? 0 : 1
#   storage_account_id = azurerm_storage_account.this.id

#   dynamic "rule" {
#     for_each = var.lifecycles
#     iterator = rule
#     content {
#       name    = "rule${rule.key}"
#       enabled = true
#       filters {
#         prefix_match = rule.value.prefix_match
#         blob_types   = ["blockBlob"]
#       }
#       actions {
#         base_blob {
#           tier_to_cool_after_days_since_modification_greater_than    = rule.value.tier_to_cool_after_days
#           tier_to_archive_after_days_since_modification_greater_than = rule.value.tier_to_archive_after_days
#           delete_after_days_since_modification_greater_than          = rule.value.delete_after_days
#         }
#         snapshot {
#           delete_after_days_since_creation_greater_than = rule.value.snapshot_delete_after_days
#         }
#       }
#     }
#   }
# }