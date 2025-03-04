#!/bin/bash
# This code will work if the user already exists, if not create a user

# Authenticate with boundary as a default admin user when it prompts please enter the password
# boundary authenticate

# creare authmethod
boundary auth-methods create password -name global-password-auth -description "global admins login usage"

BOUNDARY_AUTH_METHOD_ID=$(boundary auth-methods list -scope-id=global -format json | jq -r '.items[] | select(.name=="global-password-auth") | .id')

export PASSWORD=$(openssl rand -base64 12)

boundary accounts create password \
  -auth-method-id=$BOUNDARY_AUTH_METHOD_ID \
  -login-name="g-adminuser" \
  -name=g_admin_account \
  -password="env://PASSWORD" \
  -description="global admin password account"

BOUNDARY_AUTH_METHOD_ACCOUNT_ID=$(boundary accounts list -auth-method-id=$BOUNDARY_AUTH_METHOD_ID -format json | jq -r '.items[] | select(.name=="g_admin_account") | .id')

# Create a user
boundary users create -name="g-adminuser" -description="global admin user" -scope-id=global

BOUNDARY_USER_ID=$(boundary users list -scope-id=global -format json | jq -r '.items[] | select(.name=="g-adminuser") | .id')

# Associate the boundary USER with AUTH_METHOD account.
boundary users set-accounts -id=$BOUNDARY_USER_ID -account=$BOUNDARY_AUTH_METHOD_ACCOUNT_ID

# create a admin role in global scope
boundary roles create \
  -scope-id=global \
  -name="g_admin_role" \
  -description="Role with admin permission"

# Store the admin role id in variable called ROLE_ID
BOUNDARY_ROLE_ID=$(boundary roles list -scope-id=global -format json | jq -r '.items[] | select(.name=="g_admin_role") | .id')

# Add grants to the role, this grant provides admin access to admins group.
boundary roles add-grants -id=$BOUNDARY_ROLE_ID -grant="ids=*;type=*;actions=*"

# create a group in global scope
boundary groups create -name="g_admin_group" -description="Admins with super powers" -scope-id=global

# Store the admin role id in variable called GROUP_ID
BOUNDARY_GROUP_ID=$(boundary groups list -scope-id=global -format json | jq -r '.items[] | select(.name=="g_admin_group") | .id')

# Add principals to the role
boundary roles add-principals -id=$BOUNDARY_ROLE_ID -principal=$BOUNDARY_GROUP_ID

# Add USER to GROUPS
boundary groups add-members -id=$BOUNDARY_GROUP_ID -member=$BOUNDARY_USER_ID



######## USERS CREATATION ORG LEVEL ########
# Important Note: When you ran the deploy.sh file the organisation will be created.

# This code will work if the user already exists, if not create a user

# List the scope id of the newly crated project
# Check for existing scopes under the global scope
echo "Available Scopes:"
# List available scopes under the global scope
SCOPES=$(boundary scopes list -scope-id=global -format json | jq -r '.items[]?.name' || echo "")

if [ -z "$SCOPES" ] || [ "$SCOPES" == "null" ]; then
    echo "No existing scopes found."
    read -p "Enter a name for the new scope: " SCOPE_NAME
    ORG_SCOPE_ID=$(boundary scopes create -scope-id=global -name="$SCOPE_NAME" -description="User-created scope" -format json | jq -r '.id')

    if [ -z "$ORG_SCOPE_ID" ] || [ "$ORG_SCOPE_ID" == "null" ]; then
        echo "Failed to create scope. Exiting."
        exit 1
    fi
else
    echo "Available Scopes:"
    echo "$SCOPES"
    read -p "Enter the scope name you want to use: " SCOPE_NAME
    ORG_SCOPE_ID=$(boundary scopes list -scope-id=global -format json | jq -r --arg name "$SCOPE_NAME" '.items[] | select(.name==$name) | .id')

    if [ -z "$ORG_SCOPE_ID" ] || [ "$ORG_SCOPE_ID" == "null" ]; then
        echo "Scope $SCOPE_NAME not found. Exiting."
        exit 1
    fi
fi

export ORG_SCOPE_ID
echo "Using Scope ID: $ORG_SCOPE_ID"

# Create AUTH_METHOD in ORG Level
boundary auth-methods create password -name org-password-auth -description "org admins login usage" -scope-id=$ORG_SCOPE_ID

BOUNDARY_ORG_AUTH_METHOD_ID=$(boundary auth-methods list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org-password-auth") | .id')

export PASSWORD=$(openssl rand -base64 12)

boundary accounts create password \
  -auth-method-id=$BOUNDARY_ORG_AUTH_METHOD_ID \
  -login-name="org-adminuser" \
  -name=org_admin_account \
  -password="env://PASSWORD" \
  -description="org admin password account"

BOUNDARY_ORG_AUTH_METHOD_ACCOUNT_ID=$(boundary accounts list -auth-method-id=$BOUNDARY_ORG_AUTH_METHOD_ID -format json | jq -r '.items[] | select(.name=="org_admin_account") | .id')

# Create a user
boundary users create -name="org-adminuser" -description="org admin user" -scope-id=$ORG_SCOPE_ID

BOUNDARY_ORG_USER_ID=$(boundary users list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org-adminuser") | .id')

# Associate the boundary USER with AUTH_METHOD account.
boundary users set-accounts -id=$BOUNDARY_ORG_USER_ID -account=$BOUNDARY_ORG_AUTH_METHOD_ACCOUNT_ID

# create a admin role in global scope
boundary roles create \
  -scope-id=$ORG_SCOPE_ID \
  -name="org_admin_role" \
  -description="Role with admin permission"

# Store the admin role id in variable called ROLE_ID
BOUNDARY_ORG_ROLE_ID=$(boundary roles list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org_admin_role") | .id')

# Add grants to the role, this grant provides admin access to admins group.
boundary roles add-grants -id=$BOUNDARY_ORG_ROLE_ID -grant="ids=*;type=*;actions=*"

# create a group in global scope
boundary groups create -name="org_admin_group" -description="Admins with super powers" -scope-id=$ORG_SCOPE_ID

# Store the admin role id in variable called GROUP_ID
BOUNDARY_ORG_GROUP_ID=$(boundary groups list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org_admin_group") | .id')

# Add principals to the role
boundary roles add-principals -id=$BOUNDARY_ORG_ROLE_ID -principal=$BOUNDARY_ORG_GROUP_ID

# Add USER to GROUPS
boundary groups add-members -id=$BOUNDARY_ORG_GROUP_ID -member=$BOUNDARY_ORG_USER_ID


###### DBAUSER creation script ########
BOUNDARY_ORG1_AUTH_METHOD_ID=$(boundary auth-methods list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org-password-auth") | .id')

export PASSWORD=$(openssl rand -base64 12)

boundary accounts create password \
  -auth-method-id=$BOUNDARY_ORG1_AUTH_METHOD_ID \
  -login-name="org-dbauser" \
  -name=org_dbauser_account \
  -password="env://PASSWORD" \
  -description="org admin password account"

BOUNDARY_ORG1_AUTH_METHOD_ACCOUNT_ID=$(boundary accounts list -auth-method-id=$BOUNDARY_ORG1_AUTH_METHOD_ID -format json | jq -r '.items[] | select(.name=="org_dbauser_account") | .id')

# Create a user
boundary users create -name="org-dbauser" -description="org admin user" -scope-id=$ORG_SCOPE_ID

BOUNDARY_ORG1_USER_ID=$(boundary users list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org-dbauser") | .id')

# Associate the boundary USER with AUTH_METHOD account.
boundary users set-accounts -id=$BOUNDARY_ORG1_USER_ID -account=$BOUNDARY_ORG1_AUTH_METHOD_ACCOUNT_ID

# create a admin role in global scope
boundary roles create \
  -scope-id=$ORG_SCOPE_ID \
  -name="org_dba_role" \
  -description="Role with admin permission"

# Store the admin role id in variable called ROLE_ID
BOUNDARY_ORG1_ROLE_ID=$(boundary roles list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org_dba_role") | .id')

# Add grants to the role, this grant provides admin access to admins group.
boundary roles add-grants -id=$BOUNDARY_ORG1_ROLE_ID -grant="ids=*;type=*;actions=*"

# create a group in global scope
boundary groups create -name="org_dba_group" -description="Admins with super powers" -scope-id=$ORG_SCOPE_ID

# Store the admin role id in variable called GROUP_ID
BOUNDARY_ORG1_GROUP_ID=$(boundary groups list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org_dba_group") | .id')

# Add principals to the role
boundary roles add-principals -id=$BOUNDARY_ORG1_ROLE_ID -principal=$BOUNDARY_ORG1_GROUP_ID

# Add USER to GROUPS
boundary groups add-members -id=$BOUNDARY_ORG1_GROUP_ID -member=$BOUNDARY_ORG1_USER_ID



####### SSH user create #######

BOUNDARY_ORG2_AUTH_METHOD_ID=$(boundary auth-methods list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org-password-auth") | .id')

export PASSWORD=$(openssl rand -base64 12)

boundary accounts create password \
  -auth-method-id=$BOUNDARY_ORG2_AUTH_METHOD_ID \
  -login-name="org-sshuser" \
  -name=org_sshuser_account \
  -password="env://PASSWORD" \
  -description="ssh user password account"

BOUNDARY_ORG2_AUTH_METHOD_ACCOUNT_ID=$(boundary accounts list -auth-method-id=$BOUNDARY_ORG2_AUTH_METHOD_ID -format json | jq -r '.items[] | select(.name=="org_sshuser_account") | .id')

# Create a user
boundary users create -name="org-sshuser" -description="org admin user" -scope-id=$ORG_SCOPE_ID

BOUNDARY_ORG2_USER_ID=$(boundary users list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org-sshuser") | .id')

# Associate the boundary USER with AUTH_METHOD account.
boundary users set-accounts -id=$BOUNDARY_ORG2_USER_ID -account=$BOUNDARY_ORG2_AUTH_METHOD_ACCOUNT_ID

# create a admin role in global scope
boundary roles create \
  -scope-id=$ORG_SCOPE_ID \
  -name="org_ssh_role" \
  -description="Role with admin permission"

# Store the admin role id in variable called ROLE_ID
BOUNDARY_ORG2_ROLE_ID=$(boundary roles list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org_ssh_role") | .id')

# Add grants to the role, this grant provides admin access to admins group.
boundary roles add-grants -id=$BOUNDARY_ORG2_ROLE_ID -grant="ids=*;type=*;actions=*"

# create a group in global scope
boundary groups create -name="org_ssh_group" -description="Admins with super powers" -scope-id=$ORG_SCOPE_ID

# Store the admin role id in variable called GROUP_ID
BOUNDARY_ORG2_GROUP_ID=$(boundary groups list -scope-id=$ORG_SCOPE_ID -format json | jq -r '.items[] | select(.name=="org_ssh_group") | .id')

# Add principals to the role
boundary roles add-principals -id=$BOUNDARY_ORG2_ROLE_ID -principal=$BOUNDARY_ORG2_GROUP_ID

# Add USER to GROUPS
boundary groups add-members -id=$BOUNDARY_ORG2_GROUP_ID -member=$BOUNDARY_ORG2_USER_ID