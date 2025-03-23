echo 'The job (update keys) is running ....'
set -x && mkdir -p /opt/test

# Set the path to the server key
KEY_PATH="/opt/test/server.key"
CERT_PATH="/opt/test/server.crt"
KEY_PATH_RSA="/opt/test/server_rsa.key"
CERT_PATH_RSA="/opt/test/server_rsa.crt"
VAULT_ADDR="http://vault:8200" # Replace with your Vault server address
VAULT_TOKEN="root"             # Use your Vault token (root or a scoped token)

# Function to base64 encode a file
base64_encode() {
  file_path=$1
  base64 "$file_path" | tr -d '\n' # Remove newlines from base64 encoded data
}

# Retrieve the encoded key and certificate from Vault
echo "Retrieving key and certificate from Vault..."
RETRIEVED_SECRET=$(curl --header "X-Vault-Token: $VAULT_TOKEN" \
  --request GET \
  $VAULT_ADDR/v1/ssl/data/server)

# Check if the retrieval was successful
if [ $? -eq 0 ]; then
  echo "Key and certificate successfully retrieved from Vault."
else
  echo "Failed to retrieve the key and certificate from Vault."
  exit 1
fi

# Extract the base64 encoded key and certificate from the retrieved secret
RETRIEVED_ENCODED_KEY=$(echo "$RETRIEVED_SECRET" | jq -r '.data.data.key')
RETRIEVED_ENCODED_CERT=$(echo "$RETRIEVED_SECRET" | jq -r '.data.data.cert')

echo "Decoding and writing the key and certificate back to files..."
echo "$RETRIEVED_ENCODED_KEY" | base64 -d >/opt/test/server.key
echo "$RETRIEVED_ENCODED_CERT" | base64 -d >/opt/test/server.crt




# handling the second 
RETRIEVED_SECRET_RSA=$(curl --header "X-Vault-Token: $VAULT_TOKEN" \
  --request GET \
  $VAULT_ADDR/v1/ssl/data/server_rsa)
# Check if the retrieval was successful
if [ $? -eq 0 ]; then
  echo "Key and certificate successfully retrieved from Vault."
else
  echo "Failed to retrieve the key and certificate from Vault."
  exit 1
fi
# Extract the base64 encoded key and certificate from the retrieved secret
RETRIEVED_ENCODED_KEY_RSA=$(echo "$RETRIEVED_SECRET_RSA" | jq -r '.data.data.key')
RETRIEVED_ENCODED_CERT_RSA=$(echo "$RETRIEVED_SECRET_RSA" | jq -r '.data.data.cert')

# Decode the base64 encoded key and certificate and write them back to files
echo "Decoding and writing the key and certificate back to files..."
echo "$RETRIEVED_ENCODED_KEY_RSA" | base64 -d >/opt/test/server_rsa.key
echo "$RETRIEVED_ENCODED_CERT_RSA" | base64 -d >/opt/test/server_rsa.crt

echo "Key and certificate have been decoded and saved as /opt/test/server.key|server_rsa.key and /opt/test/server.crt|server_rsa.crt."
