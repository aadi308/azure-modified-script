#!/bin/bash

# Create two empty arrays
rg=()
sa=()

OUTPUT_CSV="updated_storage_accounts_tls_version.csv"
subscription="$1"
echo "$subscription ........."

# Set the current subscription
az account set --subscription "$subscription"

# Initialize the CSV file with headers
echo "Subscription,Resource Group,Storage Account Name,Action" > "$OUTPUT_CSV"

# Flags to differentiate between the arrays
in_array1=false

# Skip the first argument (subscription value)
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

        echo "Processing Resource Group: $resource_group, Storage Account: $storage_account"

        # Get the current TLS version
        current_tls=$(az storage account show -n $storage_account -g $resource_group --query 'minimumTlsVersion' -o tsv)

        if [ "$current_tls" == "TLS1_2" ]; then
            echo "$subscription,$resource_group,$storage_account,No action taken (TLS version is already 1.2)" >> "$OUTPUT_CSV"
        else
            # Update the Storage Account to use the latest TLS version
            az storage account update --name $storage_account --resource-group $resource_group --min-tls-version TLS1_2

            echo "$subscription,$resource_group,$storage_account,Updated TLS version to 1.2" >> "$OUTPUT_CSV"
            echo "Storage Account updated to use the latest TLS version: $storage_account"
        fi
    done
done
