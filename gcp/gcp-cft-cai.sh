#!/bin/bash -e
#!/usr/bin/env bash
# gcp-cft-cai.sh from https://github.com/wilsonmar/DevSecOps/blob/main/gcp-cft-cai.sh
# with video at https://www.youtube.com/watch?v=ixxehIF86RY
# based on Qwiklabs GSP698 https://googlecoursera.qwiklabs.com/focuses/29820714?parent=lti_session
# referenced from https://www.coursera.org/projects/googlecloud-securing-google-cloud-with-cft-scorecard-dwrbx
# CFT explained at https://wilsonmar.github.io/gcp/#gcp-cft-cai
# Partially implements https://github.com/GoogleCloudPlatform/cloud-foundation-toolkit/blob/master/cli/docs/scorecard.md

# To run this script, copy and paste this command in Google Cloud Shell (GCS) online:
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/wilsonmar/DevSecOps/master/gcp/gcp-cft-cai.sh)" -v -I

# CAI = Cloud Asset Inventory

echo "## Task 0. Set global variables:"
export GOOGLE_REGION="us-central1"
export GOOGLE_PROJECT=$DEVSHELL_PROJECT_ID
export CAI_BUCKET_NAME=cai-$GOOGLE_PROJECT
echo "GOOGLE_PROJECT=$GOOGLE_PROJECT, export CAI_BUCKET_NAME=$CAI_BUCKET_NAME"

echo "# Set variables to help with the new constraint creation:"
# look at roles/editor, too.
export USER_ACCOUNT="$(gcloud config get-value core/account)"
export PROJECT_NUMBER=$(gcloud projects describe $GOOGLE_PROJECT --format="get(projectNumber)")
echo "USER_ACCOUNT=$USER_ACCOUNT, PROJECT_NUMBER=$PROJECT_NUMBER"


echo "## Task 1.1. Install the CFT Scorecard CLI utility:"

# Enable Cloud Asset API in your project:
gcloud services enable cloudasset.googleapis.com --project $GOOGLE_PROJECT

# Create the default Cloud Asset service account:
gcloud beta services identity create \
    --service=cloudasset.googleapis.com --project=$GOOGLE_PROJECT

# Grant the storage admin role to the cloud assets service account:
gcloud projects add-iam-policy-binding ${GOOGLE_PROJECT}  \
    --member=serviceAccount:service-$(gcloud projects list --filter="$GOOGLE_PROJECT" --format="value(PROJECT_NUMBER)")@gcp-sa-cloudasset.iam.gserviceaccount.com \
    --role=roles/storage.admin


echo "## # Task 1.2. Clone the Forseti Policy Library:"

# It enforces policies in the policy-library/policies/constraints folder
if [ -d "policy-library" ]; then
    rm -rf policy-library
fi
git clone https://github.com/forseti-security/policy-library.git

# Copy a sample policy from the samples directory into the constraints directory.
DENY_LIST_PATH="policy-library/policies/constraints/storage_denylist_public.yaml"
if [ -f "$DENY_LIST_PATH" ]; then
    rm -rf "$DENY_LIST_PATH"
fi
cp policy-library/samples/storage_denylist_public.yaml \
   policy-library/policies/constraints/
ls -al $DENY_LIST_PATH


# Create bucket to hold the data that Cloud Asset Inventory (CAI) will export:
# ??? check if already created ???
gsutil mb -l $GOOGLE_REGION -p $GOOGLE_PROJECT gs://$CAI_BUCKET_NAME


echo "## Task 2.1. Collect data for the CFT Scorecard using Cloud Asset Inventory (CAI):"
# input to CFT Scorecard is resource and IAM data, and the policy-library folder.
# use CAI to generate the resource and IAM policy information for the project.

echo "# Export resource data:"
gcloud asset export \
    --output-path=gs://$CAI_BUCKET_NAME/resource_inventory.json \
    --content-type=resource \
    --project=$GOOGLE_PROJECT
  
  # --project=... could instead specify --folder or --organization

echo "# Export IAM data:"
gcloud asset export \
    --output-path=gs://$CAI_BUCKET_NAME/iam_inventory.json \
    --content-type=iam-policy \
    --project=$GOOGLE_PROJECT

echo "# Export org policy data:"
gcloud asset export \
    --output-path=gs://$CAI_BUCKET_NAME/org_policy_inventory.json \
    --content-type=org-policy \
    --project=$GOOGLE_PROJECT

echo "# Export access policy data:"
gcloud asset export \
    --output-path=gs://$CAI_BUCKET_NAME/access_policy_inventory.json \
    --content-type=access-policy \
    --project=$GOOGLE_PROJECT

# Per output, to check the status of the operation:
# gcloud asset operations describe projects/911159646139/operations/ExportAssets/ACCESS_POLICY/6ed01597e78f4c6d250e0691828b844d


echo "## Task 3. Analyze CAI data with CFT scorecard:"

# Download the CFT scorecard CLI executable and make it executable:
unamestr=$(uname)
if [[ "$unamestr" == 'Linux' ]]; then
   curl -o cft https://storage.googleapis.com/cft-cli/latest/cft-linux-amd64
   ls -al cft
      # 
   chmod +x cft
elif [[ "$unamestr" == 'FreeBSD' ]]; then
   curl -o cft https://storage.googleapis.com/cft-cli/latest/cft-linux-amd64
   ls -al cft
      # 
   chmod +x cft
elif [[ "$unamestr" == 'Darwin' ]]; then
   curl -o cft https://storage.googleapis.com/cft-cli/latest/cft-darwin-amd64
   ls -al cft
      # -rw-r--r--  1 wilsonmar  staff  92061856 Aug  9 22:32 cft
   chmod +x cft
elif [[ "$unamestr" == 'Windows' ]]; then
   curl -o cft.exe https://storage.googleapis.com/cft-cli/latest/cft-windows-amd64
fi


echo "### CFT scorecard version and menu: ++"
cft 

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


# allowlist all the valid accounts:
echo "# Add a new policy to allowlist the IAM Editor Role:"
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


# Per https://github.com/GoogleCloudPlatform/cloud-foundation-toolkit/blob/master/cli/docs/scorecard.md
# echo "# create a public GCS bucket to trigger a violation:"
#gsutil mb gs://$PUBLIC_BUCKET_NAME
#gsutil iam ch allUsers:objectViewer gs://$PUBLIC_BUCKET_NAME


echo "# Run CFT scorecard to find issues with the new policies:"
./cft scorecard --policy-path=policy-library/ --bucket=$CAI_BUCKET_NAME
retVal=$?  # capture the OS return code from the previous command above.
if [ $retVal -ne 0 ]; then
    echo "Error found in CFT scorecard!"
    echo "# TODO: Fix and ReRun CFT scorecard to verify that issues are fixed."
    # exit $retVal
fi


#echo "# Report (defined in OPA Rego language): ++"
# echo "Reuse the same CAI export generated for Scorecard "
# echo "Download the report library:"
# git clone https://github.com/GoogleCloudPlatform/cloud-foundation-toolkit.git
#./cft report --query-path <path_to_cloud-foundation-toolkit>/reports/sample \
#    --dir-path <path-to-directory-containing-cai-export> \
#    --output-path <path-to-directory-for-report-output>

# echo "# Create a directory to store report output:"
# mkdir reports
# echo "# Run the CFT report:"
#./cft report --query-path cloud-foundation-toolkit/reports/sample \
#    --dir-path ./cai-dir \
#    --output-path ./reports

# You should now see an editor who is not in your organization. 



# END