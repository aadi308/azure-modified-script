#!/bin/bash

# Create two empty arrays
rg=()
sa=()

OUTPUT_CSV="modified_storage_accounts.csv"
subscription="$1"
ipaddress="$2"

echo "$subscription ........."

# Set the current subscription
az account set --subscription "$subscription"

# Initialize the CSV file with headers
echo "Subscription,Resource Group,Storage Account Name,Action" > "$OUTPUT_CSV"

# Flags to differentiate between the arrays
in_array1=false

# Skip the first two arguments (subscription value and IP address)
shift
shift

# Loop through the remaining command-line arguments
for arg in "$@"; do
    if [ "$arg" == "--rg" ]; then
        # Switch to adding elements to array1
        in_array1=true
    elif [ "$arg" == "--sa" ]; then
        # Switch to adding elements to array2
        in_array1=false
    else
        # Add the argument to the appropriate array
        if [ "$in_array1" == true ]; then
            rg+=("$arg")
        else
            sa+=("$arg")
        fi
    fi
done

# Loop through each resource group

for resource_group in "${rg[@]}"; do
    for storage_account in "${sa[@]}"; do
        # Check if there are any open network rules
        open_network_rule=$(az storage account show -n $storage_account -g $resource_group --query "networkRuleSet.defaultAction")
        
        if [ "$open_network_rule" == "\"Allow\"" ]; then
            # Remove open network rule
            az storage account update -n $storage_account -g $resource_group --default-action Deny
            
            # Add limited access rule
            az storage account network-rule add --resource-group $resource_group --account-name $storage_account --ip-address "$ipaddress"
            
            echo "$subscription,$resource_group,$storage_account,Removed open rule and added limited access rule whose ip-address is, $ipaddress" >> "$OUTPUT_CSV"
        else
            echo "$subscription,$resource_group,$storage_account,No action taken (No open network rule found)" >> "$OUTPUT_CSV"
        fi
    done
done
