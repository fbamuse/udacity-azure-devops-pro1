variable "subscription_id" {
    type        = string
    description = "Subscription ID for Azure"
}
variable "client_id" {
    type        = string
    description = "App ID in Azure Service Principal where we want to pass the auth"
}
variable "client_secret" {
    type        = string
    description = "Password in Azure Service Principal where we want to pass the auth"
}

variable "tenant_id" {
    type        = string
    description = "Tenant in Azure Service Principal where we want to pass the auth"
}

variable "region" {
    default="East US"
    description = "azure region"
}
variable  num{
    type        = number
    default=2
    description = "the number of VM"
}
variable "prefix"{
    type        = string
    default="2021-01-18"
    description = "Prefix for naming"
}
variable "userid"{
    type        = string
    default="bamuse"
    description = "user account for VM"
}
variable "passwd"{
    type        = string
    default="!1234QWERTqwert"
    description = "password for VM"
}