param appName string
param location string = resourceGroup().location

var storageAccountName = 'st${appName}'
var insightsName = 'appi-${appName}'
var webAppHostingPlanName = 'plan-${appName}'
var webAppName = 'app-${appName}'
var functionHostingPlanName = 'plan-func-${appName}'
var functionName = 'func-${appName}'

// Azure built-in role to read and write storage table data
var storageTableDataContributorRoleId = '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: insightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
  tags: {
    'hidden-link:/subscriptions/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/sites/${functionName}': 'Resource'
    'hidden-link:/subscriptions/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/sites/${webAppName}': 'Resource'
  }
}

resource webAppHostingPlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: webAppHostingPlanName
  location: location
  sku: {
    name: 'F1'
  }
}

resource webApp 'Microsoft.Web/sites@2018-11-01' = {
  name: webAppName
  location: location
  tags: {
    'hidden-related:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${webAppHostingPlan.name}': 'Resource'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: webAppHostingPlan.id
    siteConfig: {
      netFrameworkVersion: 'v5.0'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
        }
      ]
    }
  }
  dependsOn: [
    webAppHostingPlan
    appInsights
  ]
}


resource functionHostingPlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: functionHostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

resource functionApp 'Microsoft.Web/sites@2020-12-01' = {
  name: functionName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: functionHostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsDashboard'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
      ]
    }
  }
  dependsOn: [
    appInsights
    functionHostingPlan
    storageAccount
  ]
}

resource storageWebRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(webApp.name, storageAccount.name, storageTableDataContributorRoleId)
  properties: {
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageTableDataContributorRoleId)
  }
  scope: storageAccount
  dependsOn: [
    storageAccount
    webApp
  ]
}
