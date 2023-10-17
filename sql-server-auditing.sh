#!/bin/bash

# Create empty arrays
rg=()
sql_servers=()
sa=()

OUTPUT_CSV="updated_sql_servers_audit_retention.csv"
subscription="$1"

echo "$subscription ........."

# Set the current subscription
az account set --subscription "$subscription"

# Initialize the CSV file with headers
echo "Subscription,Resource Group,SQL Server Name,Audit Retention Action,Audit Retention (Days),Storage Account Name" > "$OUTPUT_CSV"

# Flags to differentiate between the arrays
in_array1=false
in_array2=false
in_array3=false

# Skip the first argument (subscription value)
shift

# Loop through the remaining command-line arguments
for arg in "$@"; do
    if [ "$arg" == "--rg" ]; then
        # Switch to adding elements to array1
        in_array1=true
        in_array2=false
        in_array3=false
    elif [ "$arg" == "--sql_servers" ]; then
        # Switch to adding elements to array2
        in_array1=false
        in_array2=true
        in_array3=false
    elif [ "$arg" == "--sa" ]; then
        # Switch to adding elements to array3
        in_array1=false
        in_array2=false
        in_array3=true
    else
        # Add the argument to the appropriate array
        if [ "$in_array1" == true ]; then
            rg+=("$arg")
        elif [ "$in_array2" == true ]; then
            sql_servers+=("$arg")
        elif [ "$in_array3" == true ]; then
            sa+=("$arg")
        fi
    fi
done

# Loop through each resource group and SQL server
for ((i=0; i<${#sql_servers[@]}; i++)); do
    resource_group=${rg[$i]}

    if [ -z "$resource_group" ]; then
        echo "Resource group not provided for SQL Server. Skipping..."
        continue
    fi

    sql_server_name=${sql_servers[$i]}

    if [ -z "$sql_server_name" ]; then
        echo "SQL Server name not provided. Skipping..."
        continue
    fi

    storage_account_name=${sa[$i]}

    if [ -z "$storage_account_name" ]; then
        echo "Storage account name not provided. Skipping..."
        continue
    fi

    # Check if the SQL server exists in the resource group
    sql_server_exists=$(az sql server show --resource-group "$resource_group" --name "$sql_server_name" --query 'name' -o tsv 2>/dev/null)

    if [ -z "$sql_server_exists" ]; then
        echo "SQL Server '$sql_server_name' not found in resource group '$resource_group'. Skipping..."
        continue
    fi

    # Get the current audit retention setting
    current_retention=$(az sql server audit-policy show --resource-group $resource_group --name $sql_server_name --query "retentionDays" -o tsv)

    # Check if the current retention is less than or equal to 90 days
    if [ $current_retention -lt 90 ]; then
        # Update the SQL server audit policy
        az sql server audit-policy update --resource-group $resource_group --name $sql_server_name --storage-account $storage_account_name --state Enabled --retention-days 91 --bsts Enabled


        echo "Audit policy updated for SQL Server: $sql_server_name"
        audit_retention_action="Updated"
        audit_retention_value="91"
    else
        echo "Audit policy for SQL Server $sql_server_name is already set to greater than 90 days."
        audit_retention_action="Already Updated"
        audit_retention_value="$current_retention"
    fi

    echo "$subscription,$resource_group,$sql_server_name,$audit_retention_action,$audit_retention_value,$storage_account_name" >> "$OUTPUT_CSV"
done
