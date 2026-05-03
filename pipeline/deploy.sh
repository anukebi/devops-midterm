#!/bin/bash

source ~/devops/env

if [ -z "$PROJECT_DIRECTORY" ] || [ -z "$DEPLOYMENT_DIRECTORY" ] || [ -z "$DEPLOYMENT_COLOR" ] || [ -z "$PORT" ]; then
  echo "Required configuration values are missing. Verify the .env file."
  exit 1
fi

if [ "$DEPLOYMENT_COLOR" != "blue" ] && [ "$DEPLOYMENT_COLOR" != "green" ]; then
  echo "Unsupported deployment slot: $DEPLOYMENT_COLOR"
  echo "Allowed values: blue or green"
  exit 1
fi


echo "Launching deployment workflow..."
echo "Application directory: $PROJECT_DIRECTORY"
echo "Release directory: $DEPLOYMENT_DIRECTORY"
echo "Selected slot: $DEPLOYMENT_COLOR"


echo "Packaging application with Maven..."
cd "$PROJECT_DIRECTORY" || exit 1
./mvnw clean package -DskipTests || { echo "Build process failed."; exit 1; }
echo "Build finished successfully."


echo "Provisioning infrastructure with Terraform..."
cd "$PROJECT_DIRECTORY/pipeline/terraform" || exit 1
terraform init
terraform validate
terraform plan -var="deployment_directory=$DEPLOYMENT_DIRECTORY" -out=tfplan
terraform apply -auto-approve -var="deployment_directory=$DEPLOYMENT_DIRECTORY"
cd "$PROJECT_DIRECTORY" || exit 1


echo "Releasing $DEPLOYMENT_COLOR version using Ansible..."
ansible-playbook "$PROJECT_DIRECTORY/pipeline/ansible/deploy.yml" \
  -i "$PROJECT_DIRECTORY/pipeline/ansible/hosts" \
  --extra-vars "color=$DEPLOYMENT_COLOR project_directory=$PROJECT_DIRECTORY"


echo "Running application health verification..."
bash "$PROJECT_DIRECTORY/pipeline/healthcheck.sh"
if [ $? -eq 0 ]; then
    echo "Health verification succeeded. Switching active version to $DEPLOYMENT_COLOR..."
  ln -sfn "$DEPLOYMENT_DIRECTORY/deployment-$DEPLOYMENT_COLOR" "$DEPLOYMENT_DIRECTORY/deployment-current"
else
   echo "Health verification failed. Starting rollback procedure..."

  DEPLOYMENT_PREVIOUS_COLOR="blue"
  [ "$DEPLOYMENT_COLOR" == "blue" ] && DEPLOYMENT_PREVIOUS_COLOR="green"

  echo "Restoring previous slot: $DEPLOYMENT_PREVIOUS_COLOR..."
  export COLOR=$DEPLOYMENT_PREVIOUS_COLOR
  ansible-playbook "$PROJECT_DIRECTORY/pipeline/ansible/deploy.yml" \
    -i "$PROJECT_DIRECTORY/pipeline/ansible/hosts" \
    --extra-vars "color=$DEPLOYMENT_COLOR project_directory=$PROJECT_DIRECTORY skip_build=true"

  echo "Checking restored version..."
  bash "$PROJECT_DIRECTORY/pipeline/healthcheck.sh"
  if [ $? -eq 0 ]; then
    echo "Rollback completed successfully with  $DEPLOYMENT_PREVIOUS_COLOR."
    ln -sfn "$DEPLOYMENT_DIRECTORY/deployment-$DEPLOYMENT_PREVIOUS_COLOR" "$DEPLOYMENT_DIRECTORY/deployment-current"
  else
    echo "Rollback did not recover the application. Manual action is required."
    exit 1
  fi
fi

echo "Deployment workflow finished."
