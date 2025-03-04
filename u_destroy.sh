#!/bin/bash

set -e  # Exit on error
set -o pipefail  # Catch pipe failures

# Function to delete a resource safely
delete_resource() {
  local type=$1
  local id=$2
  local name=$3
  
  if [ -n "$id" ] && [ "$id" != "null" ]; then
    boundary $type delete -id $id
    echo "Deleted $type: $name"
  else
    echo "$type: $name not found, skipping."
  fi
}

# Authenticate with Boundary
# boundary authenticate

# Delete Global Scope Resources
delete_resource users "$(boundary users list -scope-id=global -format json | jq -r '.items[] | select(.name=="g-adminuser") | .id')" "g-adminuser"
delete_resource groups "$(boundary groups list -scope-id=global -format json | jq -r '.items[] | select(.name=="g_admin_group") | .id')" "g_admin_group"
delete_resource roles "$(boundary roles list -scope-id=global -format json | jq -r '.items[] | select(.name=="g_admin_role") | .id')" "g_admin_role"
delete_resource auth-methods "$(boundary auth-methods list -scope-id=global -format json | jq -r '.items[] | select(.name=="global-password-auth") | .id')" "global-password-auth"

# Organization Scope Selection
SCOPES=$(boundary scopes list -scope-id=global -format json | jq -r '.items[]?.name' || echo "")

if [ -z "$SCOPES" ] || [ "$SCOPES" == "null" ]; then
    echo "No existing scopes found."
    read -p "Enter a name for the new scope: " SCOPE_NAME
    ORG_SCOPE_ID=$(boundary scopes create -scope-id=global -name="$SCOPE_NAME" -description="User-created scope" -format json | jq -r '.id')
else
    echo "Available Scopes:"
    echo "$SCOPES"
    read -p "Enter the scope name you want to use: " SCOPE_NAME
    ORG_SCOPE_ID=$(boundary scopes list -scope-id=global -format json | jq -r --arg name "$SCOPE_NAME" '.items[] | select(.name==$name) | .id')
fi

export ORG_SCOPE_ID
echo "Using Scope ID: $ORG_SCOPE_ID"

# Delete Organization Resources
delete_resource users "$(boundary users list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org-adminuser") | .id')" "org-adminuser"
delete_resource groups "$(boundary groups list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org_admin_group") | .id')" "org_admin_group"
delete_resource roles "$(boundary roles list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org_admin_role") | .id')" "org_admin_role"
delete_resource auth-methods "$(boundary auth-methods list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org-password-auth") | .id')" "org-password-auth"

delete_resource users "$(boundary users list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org-dbauser") | .id')" "org-dbauser"
delete_resource groups "$(boundary groups list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org_dba_group") | .id')" "org_dba_group"
delete_resource roles "$(boundary roles list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org_dba_role") | .id')" "org_dba_role"

# Delete SSH User and Resources
delete_resource accounts "$(boundary accounts list -auth-method-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org_sshuser_account") | .id')" "org_sshuser_account"
delete_resource users "$(boundary users list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org-sshuser") | .id')" "org-sshuser"
delete_resource roles "$(boundary roles list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org_ssh_role") | .id')" "org_ssh_role"
delete_resource groups "$(boundary groups list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org_ssh_group") | .id')" "org_ssh_group"

# delete_resource scopes "$ORG_SCOPE_ID" "Organization Scope"

echo "Cleanup complete!"
