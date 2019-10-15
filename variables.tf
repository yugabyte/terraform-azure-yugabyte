variable "cluster_name" {
  description = "The name for the cluster (universe) being created."
  type        = string
}

variable "use_public_ip_for_ssh" {
  description = "Flag to control use of public or private ips for ssh."
  default     = "true"
  type        = string
}

variable "replication_factor" {
  description = "The replication factor for the universe."
  default     = 3
  type        = string
}

variable "node_count" {
  description = "The number of nodes to create YugaByte Db Cluter"
  default     = 3
  type        = string
}

variable "ssh_private_key" {
  description = "The private key to use when connecting to the instances."
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key to be use when creating the instances."
  type        = string
}

variable "ssh_user" {
  description = "User name to ssh YugaByte Node to configure cluster"
  type        = string
}

variable "vm-size" {
  description = "Type of Node to be used for YugaByte DB node "
  default     = "Standard_DS1_v2"
  type        = string
}

variable "yb_edition" {
  description = "The edition of YugaByteDB to install"
  default     = "ce"
  type        = string
}

variable "yb_download_url" {
  description = "The download location of the YugaByteDB edition"
  default     = "https://downloads.yugabyte.com"
  type        = string
}

variable "yb_version" {
  description = "The version number of YugaByteDB to install"
  default     = "2.1.4.0"
  type        = string
}

variable "region_name" {
  description = "Region name for Azure"
  default     = "eastus"
  type        = string
}

variable "disk_size" {
  description = "Disk size for YugaByte DB nodes"
  default     = "50"
  type        = string
}

variable "prefix" {
  description = "Prefix prepended to all resources created."
  default     = "yugabyte-"
  type        = string
}

variable "resource_group" {
  description = "Resource group name for Azure"
  default     = "null"
  type        = string
}

variable "subnet_count" {
  description = "Number of sunbnet to be created"
  default     = 3
  type        = string
}

variable "zone_list" {
  description = "avability zone list"
  default     = ["1", "2", "3"]
  type        = list(string)
}
