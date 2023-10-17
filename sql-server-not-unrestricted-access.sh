#!/bin/bash

# Create empty arrays
rg=()
sql_servers=()

OUTPUT_CSV="updated_sql_servers_public_access.csv"
subscription="$1"
echo "$subscription ........."

# Set the current subscription
az account set --subscription "$subscription"

# Initialize the CSV file with headers
echo "Subscription,Resource Group,SQL Server Name,Action,Public Network Access" > "$OUTPUT_CSV"

# Flags to differentiate between the arrays
in_array1=false
in_array2=false

# Skip the first argument (subscription value)
shift

# Loop through the remaining command-line arguments
for arg in "$@"; do
    if [ "$arg" == "--rg" ]; then
        in_array1=true
        in_array2=false
    elif [ "$arg" == "--sql_servers" ]; then
        in_array1=false
        in_array2=true
    else
        if [ "$in_array1" == true ]; then
            rg+=("$arg")
        elif [ "$in_array2" == true ]; then
            sql_servers+=("$arg")
        fi
    fi
done

# Loop through each resource group and SQL server
for ((i=0; i<${#sql_servers[@]}; i++)); do
    resource_group=${rg[$i]}
    sql_server_name=${sql_servers[$i]}

    if [ -z "$resource_group" ] || [ -z "$sql_server_name" ]; then
        echo "Resource group or SQL Server name not provided. Skipping..."
        continue
    fi

    # Check if the SQL server exists in the resource group
    sql_server_exists=$(az sql server show --resource-group "$resource_group" --name "$sql_server_name" --query 'name' -o tsv 2>/dev/null)

    if [ -z "$sql_server_exists" ]; then
        echo "SQL Server '$sql_server_name' not found in resource group '$resource_group'. Skipping..."
        continue
    fi

    # Get the current public network access setting
    public_network_access=$(az sql server show --resource-group $resource_group --name $sql_server_name --query "publicNetworkAccess" -o tsv)

    if [ "$public_network_access" == "Enabled" ]; then
        # Update the SQL server to disable public network access
        az sql server update --resource-group $resource_group --name $sql_server_name --enable-public-network=false

        echo "SQL Server: $subscription,$resource_group,$sql_server_name,Disabled,$public_network_access" >> "$OUTPUT_CSV"
    else
        echo "Public network access is already disabled for SQL Server $sql_server_name."
        echo "SQL Server: $subscription,$resource_group,$sql_server_name,Already Disabled,$public_network_access" >> "$OUTPUT_CSV"
    fi
done
