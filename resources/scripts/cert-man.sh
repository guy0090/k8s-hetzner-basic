#!/bin/bash
# Only run if the first node is calling this script
if [[ "$1" == "1" ]]; then
    # Wait for ingress to start
    echo "Waiting for ingress to start..."
    sleep 70s

    helm install \
    cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --version v1.11.0 \
    --set installCRDs=true \
    --set startupapicheck.timeout=5m \
    --set webhook.securePort=12050

    # Grab a random Email
    ACME_MAIL=$(curl -sX GET "https://www.1secmail.com/api/v1/?action=genRandomMailbox&count=1" | jq -r .[0])
    ISSUER_MANIFEST="https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/staging-issuer.yaml"

    # Replace with above for a production certificate. Should NOT be used since we're using
    # Hetzner's RDNS and not our own, but it will work.
    # ISSUER_MANIFEST="https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/production-issuer.yaml"

    # Create 'examples' namespace
    kubectl create namespace examples

    # Download the Let's Encrypt staging Issuer template and create it
    curl -sX GET "$ISSUER_MANIFEST" | sed "s/user@example.com/$ACME_MAIL/g" | kubectl create -f - -n examples

    # Add example service
    # Replace 'staging' with 'prod' if using production Issuer
    envsubst < ~/manifests/HelloWorld.staging.yaml | kubectl apply -f -
fi