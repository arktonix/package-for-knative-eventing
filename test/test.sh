#!/bin/bash

set -eu

echo -e "\nš¢ Setting up Kubernetes cluster...\n"

kapp deploy -a test-setup -f test/test-setup -y
kubectl config set-context --current --namespace=carvel-test

# Wait for the generation of a token for the new Service Account
while [ $(kubectl get configmap --no-headers | wc -l) -eq 0 ] ; do
  sleep 3
done

echo -e "š¦ Deploying Carvel package...\n"

cd package
kctrl dev -f package-resources.yml --local  -y
cd ..

echo -e "š® Verifying package..."

status=$(kapp inspect -a knative-eventing.app --status --json | jq '.Lines[1]' -)
if [[ '"Succeeded"' == ${status} ]]; then
    echo -e "ā The package has been installed successfully.\n"
else
    echo -e "š« Something wrong happened during the installation of the package.\n"
    exit 1
fi

echo -e "š¾ Installing default broker..."

kapp deploy -a test-data -f test/test-data -y

kubectl wait \
  --for=condition=ready broker/default \
  --timeout=30s

echo -e "š® Verifying default broker..."

status=$(kapp inspect -a test-data --status --json | jq '.Lines[1]' -)
if [[ '"Succeeded"' == ${status} ]]; then
    echo -e "ā The default broker has been initialized successfully.\n"
    exit 0
else
    echo -e "š« Something wrong happened during the initialization of the default broker.\n"
    exit 1
fi
