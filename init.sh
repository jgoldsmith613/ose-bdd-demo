#!/bin/bash

SCRIPT_BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


OSE_CI_PROJECT="ci"
OSE_BDD_DEV_PROJECT="coolstore-bdd-dev"
OSE_BDD_PROD_PROJECT="coolstore-bdd-prod"
OSE_CLI_USER="admin"
OSE_CLI_PASSWORD="admin"
OSE_CLI_HOST="https://10.1.2.2:8443"
GIT_REF="master"
KIE_SERVER_USER="kieserver"
KIE_SERVER_PASSWORD="bdddemo"


oc login -u ${OSE_CLI_USER} -p ${OSE_CLI_PASSWORD} ${OSE_CLI_HOST} --insecure-skip-tls-verify=true

echo "Creating new CI Project (${OSE_CI_PROJECT})..."
echo

# Create New Project
oc new-project ${OSE_CI_PROJECT}

echo "Creating Jenkins Service Account and Adding Permissions..."

# Create New Service Account
oc process -v NAME=jenkins -f "${SCRIPT_BASE_DIR}/support/templates/create-sa.json" | oc create -f -

# Create Jenkins Service Account
oc policy add-role-to-user edit system:serviceaccount:$OSE_CI_PROJECT:jenkins

# Process RHEL Template
oc create -f"${SCRIPT_BASE_DIR}/support/templates/rhel7-is.json"

# Import Upstream Image
oc import-image rhel7

# Process Jenkins Template
oc process -v APPLICATION_NAME=jenkins,GIT_REF=${GIT_REF} -f "${SCRIPT_BASE_DIR}/support/templates/jenkins-template.json" | oc create -f -

# Process Nexus Template
oc process -v APPLICATION_NAME=nexus,GIT_REF=${GIT_REF} -f "${SCRIPT_BASE_DIR}/support/templates/nexus-template.json" | oc create -f -

echo
echo "Creating new BDD Dev Project (${OSE_BDD_DEV_PROJECT})..."
echo

# Create new Dev Project
oc new-project ${OSE_BDD_DEV_PROJECT}

# Grant Jenkins Service Account Access to Dev Project
oc policy add-role-to-user edit system:serviceaccount:$OSE_CI_PROJECT:jenkins -n ${OSE_BDD_DEV_PROJECT}

echo
echo "Creating Coolstore App in ${OSE_BDD_DEV_PROJECT}..."
echo
# Process app-store template
oc process -v KIE_SERVER_USER=${KIE_SERVER_USER},KIE_SERVER_PASSWORD=${KIE_SERVER_PASSWORD} -f "${SCRIPT_BASE_DIR}/support/templates/coolstore-bdd-app.json" | oc create -f -


echo
echo "Creating Coolstore Rules in ${OSE_BDD_DEV_PROJECT}..."
echo
# Process rules template
oc process -v KIE_SERVER_USER=${KIE_SERVER_USER},KIE_SERVER_PASSWORD=${KIE_SERVER_PASSWORD} -f "${SCRIPT_BASE_DIR}/support/templates/coolstore-bdd-rules.json" | oc create -f -

echo
echo "Creating new BDD Prod Project (${OSE_BDD_PROD_PROJECT})..."
echo
# Create new Dev Project
oc new-project ${OSE_BDD_PROD_PROJECT}

# Grant Jenkins Service Account Access to Dev Project
oc policy add-role-to-user edit system:serviceaccount:$OSE_CI_PROJECT:jenkins -n ${OSE_BDD_PROD_PROJECT}

echo
echo "Creating Coolstore App in ${OSE_BDD_PROD_PROJECT}..."
echo
# Process app-store template
oc process -v KIE_SERVER_USER=${KIE_SERVER_USER},KIE_SERVER_PASSWORD=${KIE_SERVER_PASSWORD} -f "${SCRIPT_BASE_DIR}/support/templates/coolstore-bdd-app-deploy.json" | oc create -f -

echo
echo "Creating Coolstore Prod in ${OSE_BDD_PROD_PROJECT}..."
echo
oc process -v KIE_SERVER_USER=${KIE_SERVER_USER},KIE_SERVER_PASSWORD=${KIE_SERVER_PASSWORD} -f "${SCRIPT_BASE_DIR}/support/templates/coolstore-bdd-rules-deploy.json" | oc create -f -


oc policy add-role-to-user edit system:serviceaccount:${OSE_BDD_PROD_PROJECT}:default -n ${OSE_BDD_DEV_PROJECT}

echo
echo "Setup Complete"
echo