variable "create_resource_group" {
  description = "Whether to create resource group and use it for all networking resources"
  type        = bool
  default     = false
}

variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  type        = string
  default     = "rg-demo"
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  type        = string
  default     = "Canada Central"
}

variable "storage_account_name" {
  description = "The name of the storage account to be created"
  type        = string
  default     = ""
}

variable "account_kind" {
  description = "The type of storage account. Valid options are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2."
  type        = string
  default     = "StorageV2"
}

variable "skuname" {
  description = "The SKUs supported by Microsoft Azure Storage. Valid options are Premium_LRS, Premium_ZRS, Standard_GRS, Standard_GZRS, Standard_LRS, Standard_RAGRS, Standard_RAGZRS, Standard_ZRS"
  type        = string
  default     = "Standard_LRS"
}

variable "access_tier" {
  description = "Defines the access tier for BlobStorage and StorageV2 accounts. Valid options are Hot and Cool."
  type        = string
  default     = "Hot"
}

# variable "blob_soft_delete_retention_days" {
#   description = "Specifies the number of days that the blob should be retained, between `1` and `365` days. Defaults to `7`"
#   type        = number
#   default     = 7
# }

# variable "container_soft_delete_retention_days" {
#   description = "Specifies the number of days that the blob should be retained, between `1` and `365` days. Defaults to `7`"
#   type        = number
#   default     = 7
# }

# variable "enable_versioning" {
#   description = "Is versioning enabled? Default to `false`"
#   type        = bool
#   default     = false
# }

# variable "last_access_time_enabled" {
#   description = "Is the last access time based tracking enabled? Default to `false`"
#   type        = bool
#   default     = false
# }

# variable "change_feed_enabled" {
#   description = "Is the blob service properties for change feed events enabled?"
#   type        = bool
#   default     = false
# }

variable "virtual_network_subnet_ids" {
  description = "List of subnets to permit access to the storage account"
  type        = list(string)
  default     = []
}

variable "virtual_network_ip_rules" {
  description = "List of IP rules to permit access to the storage account"
  type        = list(string)
  default     = []
}

variable "containers_list" {
  description = "List of containers to create"
  type        = list(string)
  default     = []
}

variable "identity_ids" {
  description = "Specifies a list of user managed identity ids to be assigned. This is required when `type` is set to `UserAssigned` or `SystemAssigned, UserAssigned`"
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "allow_blob_public_access" {
  description = "Whether to allow public access to blobs"
  type        = bool
  default     = false
}
