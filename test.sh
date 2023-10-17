#!/bin/bash

# Define the JSON content as a string
json_content='{
    "mode": "All",
    "policyRule": {
        "if": {
            "allOf": [
                {
                    "field": "type",
                    "equals": "Microsoft.Sql/servers"
                },
                {
                    "field": "kind",
                    "notContains": "analytics"
                }
            ]
        },
        "then": {
            "effect": "[parameters('effect')]",
            "details": {
                "type": "Microsoft.Sql/servers/vulnerabilityAssessments",
                "name": "default",
                "existenceCondition": {
                    "field": "Microsoft.Sql/servers/vulnerabilityAssessments/recurringScans.isEnabled",
                    "equals": "True"
                },
                "roleDefinitionIds": [
                    "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
                ],
                "deployment": {
                    "properties": {
                        "mode": "incremental",
                        "template": {
                            "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
                            "contentVersion": "1.0.0.0",
                            "parameters": {
                                "serverName": {
                                    "type": "string"
                                },
                                "location": {
                                    "type": "string"
                                }
                            },
                            "variables": {
                                "getDeploymentName": "[concat('PolicyDeployment-Get-', parameters('serverName'))]",
                                "updateDeploymentName": "[concat('PolicyDeployment-Update-', parameters('serverName'))]"
                            },
                            "resources": [
                                {
                                    "apiVersion": "2020-06-01",
                                    "type": "Microsoft.Resources/deployments",
                                    "name": "[variables('getDeploymentName')]",
                                    "properties": {
                                        "mode": "Incremental",
                                        "template": {
                                            "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                                            "contentVersion": "1.0.0.0",
                                            "resources": [],
                                            "outputs": {}
                                        }
                                    }
                                },
                                {
                                    "apiVersion": "2020-06-01",
                                    "type": "Microsoft.Resources/deployments",
                                    "name": "[variables('updateDeploymentName')]",
                                    "properties": {
                                        "mode": "Incremental",
                                        "expressionEvaluationOptions": {
                                            "scope": "inner"
                                        },
                                        "template": {
                                            "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                                            "contentVersion": "1.0.0.0",
                                            "parameters": {
                                                "location": {
                                                    "type": "string"
                                                },
                                                "serverName": {
                                                    "type": "string"
                                                }
                                            },
                                            "variables": {
                                                "serverResourceGroupName": "[resourceGroup().name]",
                                                "subscriptionId": "[subscription().subscriptionId]",
                                                "uniqueStorage": "[uniqueString(variables('subscriptionId'), variables('serverResourceGroupName'), parameters('location'))]",
                                                "storageName": "[tolower(concat('sqlva', variables('uniqueStorage')))]"
                                            },
                                            "resources": [
                                                {
                                                    "type": "Microsoft.Storage/storageAccounts",
                                                    "apiVersion": "2019-04-01",
                                                    "name": "[variables('storageName')]",
                                                    "location": "[parameters('location')]",
                                                    "sku": {
                                                        "name": "Standard_LRS"
                                                    },
                                                    "kind": "StorageV2",
                                                    "properties": {
                                                        "minimumTlsVersion": "TLS1_2",
                                                        "supportsHttpsTrafficOnly": "true",
                                                        "allowBlobPublicAccess": "false"
                                                    }
                                                },
                                                {
                                                    "type": "Microsoft.Sql/servers/securityAlertPolicies",
                                                    "apiVersion": "2017-03-01-preview",
                                                    "name": "[concat(parameters('serverName'), '/Default')]",
                                                    "properties": {
                                                        "state": "Enabled",
                                                        "emailAccountAdmins": true
                                                    }
                                                },
                                                {
                                                    "type": "Microsoft.Sql/servers/vulnerabilityAssessments",
                                                    "apiVersion": "2018-06-01-preview",
                                                    "name": "[concat(parameters('serverName'), '/Default')]",
                                                    "dependsOn": [
                                                        "[concat('Microsoft.Storage/storageAccounts/', variables('storageName'))]",
                                                        "[concat('Microsoft.Sql/servers/', parameters('serverName'), '/securityAlertPolicies/Default')]"
                                                    ],
                                                    "properties": {
                                                        "storageContainerPath": "[concat(reference(resourceId('Microsoft.Storage/storageAccounts', variables('storageName'))).primaryEndpoints.blob, 'vulnerability-assessment')]",
                                                        "storageAccountAccessKey": "[listKeys(resourceId('Microsoft.Storage/storageAccounts', variables('storageName')), '2018-02-01').keys[0].value]",
                                                        "recurringScans": {
                                                            "isEnabled": true,
                                                            "emailSubscriptionAdmins": true,
                                                            "emails": []
                                                        }
                                                    }
                                                }
                                            ],
                                            "outputs": {}
                                        }
                                    }
                                }
                            ],
                            "outputs": {}
                        },
                        "parameters": {
                            "serverName": {
                                "value": "[parameters('serverName')]"
                            },
                            "location": {
                                "value": "[parameters('location')]"
                            }
                        }
                    }
                }
            }
        }
    },
    "parameters": {
        "serverName": {
            "value": "[field('name')]"
        },
        "location": {
            "value": "[field('location')]"
        }
    }
}'

# Save the JSON content to a file
echo $json_content > va_policy.json

# Apply the policy using Azure CLI
az policy assignment create --name "apply-va-policy" --display-name "Apply Vulnerability Assessment Policy" --policy "va_policy.json" --params "{\"effect\":{\"value\":\"DeployIfNotExists\"}}" --scope "/subscriptions/<subscription_id>/resourceGroups/<resource_group_name>"

# Clean up the JSON file (optional)
rm va_policy.json
