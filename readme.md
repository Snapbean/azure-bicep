## Development

https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install

## Installation

1. Define variables

```
$APP_NAME = "<appname>"
$RESOURCE_GROUP = "rg-$APP_NAME"
$BICEP_FILE = "main.bicep"
$PARAMETERS_FILE = "@main.parameters-test.json"
$LOCATION = "WestEurope"
```

3. Create resource group

```
az group create -n $RESOURCE_GROUP -l $LOCATION
```

4. Validate template

```
az deployment group validate --resource-group $RESOURCE_GROUP --template-file $BICEP_FILE --parameters $PARAMETERS_FILE --parameters "appName=$APP_NAME"
```

3. What if

```
az deployment group what-if --resource-group $RESOURCE_GROUP --template-file $BICEP_FILE --parameters $PARAMETERS_FILE --parameters "appName=$APP_NAME"
```

4. Deploy template

```
az deployment group create --resource-group $RESOURCE_GROUP --template-file $BICEP_FILE --parameters $PARAMETERS_FILE --parameters "appName=$APP_NAME"
```
