
// Main Bicep deployment file for Azure and Graph resources:
// Created by: Jan Vidar Elven
// Last Updated: 22.05.2024

targetScope = 'subscription'

// Main Parameters for Existing Resources
param resourceGroupName string = 'rg-<your-resource-group>'
param managedIdentityName string = 'mi-<your-managed-identity>'

// Initialize the Graph provider
provider microsoftGraph

// Get existing Azure resources for Resource Group and Managed Identity
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: resourceGroupName
}
resource userManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
  scope: resourceGroup(rg.name)
}

// Get the Principal Id of the Managed Identity resource
resource miSpn 'Microsoft.Graph/servicePrincipals@v1.0' existing = {
  appId: userManagedIdentity.properties.clientId
  // Tip! If using a System Assigned managed identity, you can refer to the resource symbolic name
  // directly and use <resourcesymbolicname>.identity.principalId for appId
}

// Get the Resource Id of the Graph resource in the tenant
resource graphSpn 'Microsoft.Graph/servicePrincipals@v1.0' existing = {
  appId: '00000003-0000-0000-c000-000000000000'
}

// Define the App Roles to assign to the Managed Identity
param appRoles array = [
  'User.Read.All'
  'Device.Read.All'
]

// Looping through the App Roles and assigning them to the Managed Identity
resource assignAppRole 'Microsoft.Graph/appRoleAssignedTo@v1.0' = [for appRole in appRoles: {
  appRoleId: (filter(graphSpn.appRoles, role => role.value == appRole)[0]).id
  principalId: miSpn.id
  resourceId: graphSpn.id
}]
