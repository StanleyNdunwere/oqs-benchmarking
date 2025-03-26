echo 'The job is running ....'
SIG_ALG="dilithium3"
VAULT_ADDR="http://vault:8200"  # Replace with your Vault server address
VAULT_TOKEN="root"  # Use your Vault token (root or a scoped token)

set -x && mkdir -p /opt/test 
cd /opt/openssl/bin
openssl version && openssl list -providers &&
openssl req -new -newkey dilithium5 -keyout /opt/test/server.key -out /opt/test/server.csr -nodes -subj "/CN=localhost" &&
openssl x509 -req -in /opt/test/server.csr -out /opt/test/server.crt -CA CA.crt -CAkey CA.key -CAcreateserial -days 30

# Set the path to the server key
KEY_PATH="/opt/test/server.key"
CERT_PATH="/opt/test/server.crt"

# Ensure key and certificate were generated
if [ ! -s "$KEY_PATH" ]; then
    echo "Error: Server key not generated!"
    exit 1
fi

if [ ! -s "$CERT_PATH" ]; then
    echo "Error: Server certificate not generated!"
    exit 1
fi

# Function to base64 encode a file
base64_encode() {
    file_path=$1
    base64 "$file_path" | tr -d '\n'  # Remove newlines from base64 encoded data
}


# Base64 encode the key and certificate
ENCODED_KEY=`base64_encode "$KEY_PATH"`
ENCODED_CERT=`base64_encode "$CERT_PATH"`

# Store the encoded key and certificate in Vault (kv-v2 secrets engine)
echo "Storing key and certificate in Vault..."
curl --header "X-Vault-Token: $VAULT_TOKEN" \
     --request POST \
     --data "{\"data\": {\"key\": \"$ENCODED_KEY\", \"cert\": \"$ENCODED_CERT\"}, \"lease_duration\": \"864000\"}" \
     $VAULT_ADDR/v1/ssl/data/server


# Generate a self-signed certificate from the CSR using standard rsa
set -x && mkdir -p /opt/test
openssl req -new -newkey rsa:4096 -keyout /opt/test/server_rsa.key -out /opt/test/server_rsa.csr -nodes -subj "/CN=localhost" &&
openssl x509 -req -in /opt/test/server_rsa.csr -out /opt/test/server_rsa.crt -signkey /opt/test/server_rsa.key -days 30

KEY_PATH_RSA="/opt/test/server_rsa.key"
CERT_PATH_RSA="/opt/test/server_rsa.crt"

# Ensure key and certificate were generated
if [ ! -s "$KEY_PATH_RSA" ]; then
    echo "Error: Server key rsa not generated!"
    exit 1
fi

if [ ! -s "$CERT_PATH_RSA" ]; then
    echo "Error: Server certificate rsa not generated!"
    exit 1
fi

ENCODED_KEY_RSA=`base64_encode "$KEY_PATH_RSA"`
ENCODED_CERT_RSA=`base64_encode "$CERT_PATH_RSA"`

curl --header "X-Vault-Token: $VAULT_TOKEN" \
     --request POST \
     --data "{\"data\": {\"key\": \"$ENCODED_KEY_RSA\", \"cert\": \"$ENCODED_CERT_RSA\"}, \"lease_duration\": \"864000\"}" \
     $VAULT_ADDR/v1/ssl/data/server_rsa


# Check if the storage was successful
if [ $? -eq 0 ]; then
    echo "Key and certificate successfully stored in Vault."
else
    echo "Failed to store the key and certificate in Vault."
    exit 1
fi