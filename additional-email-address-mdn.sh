#!/bin/bash

# Function to enable notifications
enable_notifications() {
    subscription_id="$1"
    api_version="2020-01-01-preview"
    url="https://management.azure.com/subscriptions/$subscription_id/providers/Microsoft.Security/securityContacts/default?api-version=$api_version"

    # JSON payload
    json_payload='{
        "properties": {
            "emails": "admin@contoso.com;admin2@contoso.com",
            "notificationsByRole": {
                "state": "On",
                "roles": ["AccountAdmin", "Owner"]
            },
            "alertNotifications": {
                "state": "On",
                "minimalSeverity": "Medium"
            },
            "phone": ""
        }
    }'

    # Update security contact
    az rest --method put --uri $url --body "$json_payload"
}

OUTPUT_CSV="enabled_subscription_owner_notifications.csv"
subscription="$1"
echo "$subscription ........."

# Set the current subscription
az account set --subscription "$subscription"

# Initialize the CSV file with headers
echo "Subscription,Action" > "$OUTPUT_CSV"

# Enable notifications
enable_notifications "$subscription"

# Record the action in CSV
echo "$subscription,Enabled" >> "$OUTPUT_CSV"

#How to run script
# ./<file_name> <subscription_id>