#!/bin/bash -e
#!/usr/bin/env bash
# gcp-cft-cai.sh from https://github.com/wilsonmar/DevSecOps/blob/main/gcp-cft-cai.sh
# Based on Qwiklabs GSP698 
# in https://www.coursera.org/projects/googlecloud-securing-google-cloud-with-cft-scorecard-dwrbx
# Explained at https://wilsonmar.github.io/gcp/#gcp-cft-cai

# To run this script, copy and paste this command in Google Cloud Shell online:
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/wilsonmar/DevSecOps/master/gcp/gcp-cft-cai.sh)" -v -I

echo "## Task 0. Set global variables:"
export GOOGLE_PROJECT=$DEVSHELL_PROJECT_ID
export CAI_BUCKET_NAME=cai-$GOOGLE_PROJECT
echo "GOOGLE_PROJECT=$GOOGLE_PROJECT, export CAI_BUCKET_NAME=$CAI_BUCKET_NAME"

echo "## Task 1.1. Install the CFT Scorecard CLI utility:"

# Enable Cloud Asset API in your project:
gcloud services enable cloudasset.googleapis.com \
        --project $GOOGLE_PROJECT

# Create the default Cloud Asset service account:
gcloud beta services identity create \
    --service=cloudasset.googleapis.com --project=$GOOGLE_PROJECT

# Grant the storage admin role to the cloud assets service account:
gcloud projects add-iam-policy-binding ${GOOGLE_PROJECT}  \
    --member=serviceAccount:service-$(gcloud projects list --filter="$GOOGLE_PROJECT" --format="value(PROJECT_NUMBER)")@gcp-sa-cloudasset.iam.gserviceaccount.com \
    --role=roles/storage.admin

echo "## # Task 1.2. Clone the Forseti Policy Library:"

# It enforces policies in the policy-library/policies/constraints folder
git clone https://github.com/forseti-security/policy-library.git

# Copy a sample policy from the samples directory into the constraints directory.
cp policy-library/samples/storage_denylist_public.yaml \
   policy-library/policies/constraints/
ls -al policy-library/policies/constraints/storage_denylist_public.yaml

# Create bucket to hold the data that Cloud Asset Inventory (CAI) will export:
gsutil mb -l us-central1 -p $GOOGLE_PROJECT gs://$CAI_BUCKET_NAME


echo "## Task 2.1. Collect data for the CFT Scorecard using Cloud Asset Inventory (CAI):"
# input to CFT Scorecard is resource and IAM data, and the policy-library folder.
# use CAI to generate the resource and IAM policy information for the project.

# Export resource data
gcloud asset export \
    --output-path=gs://$CAI_BUCKET_NAME/resource_inventory.json \
    --content-type=resource \
    --project=$GOOGLE_PROJECT
# Export IAM data
gcloud asset export \
    --output-path=gs://$CAI_BUCKET_NAME/iam_inventory.json \
    --content-type=iam-policy \
    --project=$GOOGLE_PROJECT
# Export org policy data
gcloud asset export \
    --output-path=gs://$CAI_BUCKET_NAME/org_policy_inventory.json \
    --content-type=org-policy \
    --project=$GOOGLE_PROJECT
# Export access policy data
gcloud asset export \
    --output-path=gs://$CAI_BUCKET_NAME/access_policy_inventory.json \
    --content-type=access-policy \
    --project=$GOOGLE_PROJECT

# Per output,  to check the status of the operation:
# gcloud asset operations describe projects/911159646139/operations/ExportAssets/ACCESS_POLICY/6ed01597e78f4c6d250e0691828b844d


echo "## Task 3. Analyze CAI data with CFT scorecard:"

# Download the CFT scorecard application and make it executable:
curl -o cft https://storage.googleapis.com/cft-cli/latest/cft-linux-amd64
ls -al cft
chmod +x cft


echo "## Task 4. Add IAM constraints to CFT scorecard:"
# to ensure you are entirely aware who has the roles/owner role aside from your allowlisted user:
# Add a new policy to blacklist the IAM Owner Role:
cat > policy-library/policies/constraints/iam_allowlist_owner.yaml << EOF
apiVersion: constraints.gatekeeper.sh/v1alpha1
kind: GCPIAMAllowedBindingsConstraintV3
metadata:
  name: allowlist_owner
  annotations:
    description: List any users granted Owner
spec:
  severity: high
  match:
    target: ["organizations/**"]
    exclude: []
  parameters:
    mode: allowlist
    assetType: cloudresourcemanager.googleapis.com/Project
    role: roles/owner
    members:
    - "serviceAccount:admiral@qwiklabs-services-prod.iam.gserviceaccount.com"
EOF

ls -al policy-library/policies/constraints/iam_allowlist_owner.yaml


echo "# Set variables to help with the new constraint creation:"
# look at roles/editor, too.
export USER_ACCOUNT="$(gcloud config get-value core/account)"
export PROJECT_NUMBER=$(gcloud projects describe $GOOGLE_PROJECT --format="get(projectNumber)")
echo "USER_ACCOUNT=$USER_ACCOUNT, PROJECT_NUMBER=$PROJECT_NUMBER"

# allowlist all the valid accounts:
# Add a new policy to allowlist the IAM Editor Role
cat > policy-library/policies/constraints/iam_identify_outside_editors.yaml << EOF
apiVersion: constraints.gatekeeper.sh/v1alpha1
kind: GCPIAMAllowedBindingsConstraintV3
metadata:
  name: identify_outside_editors
  annotations:
    description: list any users outside the organization granted Editor
spec:
  severity: high
  match:
    target: ["organizations/**"]
    exclude: []
  parameters:
    mode: allowlist
    assetType: cloudresourcemanager.googleapis.com/Project
    role: roles/editor
    members:
    - "user:$USER_ACCOUNT"
    - "serviceAccount:**$PROJECT_NUMBER**gserviceaccount.com"
    - "serviceAccount:$GOOGLE_PROJECT**gserviceaccount.com"
EOF

ls -al policy-library/policies/constraints/iam_identify_outside_editors.yaml


echo "# Rerun CFT scorecard to find issues with the new policies:"
./cft scorecard --policy-path=policy-library/ --bucket=$CAI_BUCKET_NAME
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error"
fi
exit $retVal

# You should now see an editor who is not in your organization. 

# END