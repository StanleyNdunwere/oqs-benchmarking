#!/bin/bash

# Navigate to OpenSSL bin directory
cd /opt/openssl/bin

# Extract the public key from the certificate
openssl x509 -in /opt/test/server_rsa.crt -pubkey -noout > /opt/test/server_rsa_public_key.pem

# File paths
RSA_PRIVATE_KEY="/opt/test/server_rsa.key"
RSA_PUBLIC_KEY="/opt/test/server_rsa_public_key.pem"
TEXT_FILE="/opt/testfiles/test_text.txt"
TEST_FILES_DIR="/opt/testfiles"

# Output file for signature
SIGNATURE_FILE="/opt/testfiles/test_text_signature_rsa.bin"

# Log files
SIGN_TIME_LOG="/opt/testfiles/test_logs/time-taken-sign-rsa.log"
VERIFY_TIME_LOG="/opt/testfiles/test_logs/time-taken-verify-rsa.log"
HASH_TIME_LOG="/opt/testfiles/test_logs/time-taken-hash-only-rsa.log"
SIZE_COMPARISON_LOG="/opt/testfiles/test_logs/signature-size-comparison.log"

# Ensure log directories exist
mkdir -p "$(dirname "$SIGN_TIME_LOG")"
mkdir -p "$(dirname "$VERIFY_TIME_LOG")"
mkdir -p "$(dirname "$HASH_TIME_LOG")"
mkdir -p "$TEST_FILES_DIR"

# Function to generate test files of varying sizes
generate_test_files() {
  echo "Generating test files of various sizes..."
  for size in 1M 50M; do
    echo "Creating test file of size $size"
    dd if=/dev/urandom of="$TEST_FILES_DIR/test_$size.bin" bs=$size count=1
  done
  echo "Test files generated."
}

# Function to calculate hash only (separate from signing)
hash_file() {
  input_file=$1
  echo "Calculating hash for $input_file..."
  
  # Measure time for hash calculation only
  echo "File name: $input_file" >> "$HASH_TIME_LOG"
  { time openssl dgst -sha256 "$input_file"; } 2>> "$HASH_TIME_LOG"
  
  echo "Hash calculated for $input_file. Time taken logged in $HASH_TIME_LOG"
  echo "-----------------------" >> "$HASH_TIME_LOG"  # Separator line
}

# Function to sign a file using RSA
sign_file() {
  input_file=$1
  signature_file=$2
  private_key=$3
  echo "Signing $input_file using RSA private key..."
  
  # Measure time and sign the file using RSA
  echo "File name: $input_file" >> "$SIGN_TIME_LOG"
  { time openssl dgst -sha256 -sign "$private_key" -out "$signature_file" "$input_file"; } 2>> "$SIGN_TIME_LOG"
  
  echo "$input_file signed and signature saved as $signature_file. Time taken logged in $SIGN_TIME_LOG"
  echo "-----------------------" >> "$SIGN_TIME_LOG"  # Separator line
  
  # Record signature size
  echo "File: $input_file" >> "$SIZE_COMPARISON_LOG"
  echo "RSA signature size: $(ls -la "$signature_file" | awk '{print $5}') bytes" >> "$SIZE_COMPARISON_LOG"
  echo "-----------------------" >> "$SIZE_COMPARISON_LOG"
}

# Function to verify a signature using RSA
verify_signature() {
  input_file=$1
  signature_file=$2
  public_key=$3
  echo "Verifying signature for $input_file using RSA public key..."
  
  # Measure time and verify the signature
  echo "File name: $input_file" >> "$VERIFY_TIME_LOG"
  { time openssl dgst -sha256 -verify "$public_key" -signature "$signature_file" "$input_file"; } 2>> "$VERIFY_TIME_LOG"
  
  echo "Signature verification completed. Time taken logged in $VERIFY_TIME_LOG"
  echo "-----------------------" >> "$VERIFY_TIME_LOG"  # Separator line
}

# Generate the test files
generate_test_files

# Clear previous logs
> "$SIGN_TIME_LOG"
> "$VERIFY_TIME_LOG"
> "$HASH_TIME_LOG"
> "$SIZE_COMPARISON_LOG"

# Run the original test 100 times on the standard text file
echo "Running standard test 5 times on $TEXT_FILE for small text file"
for i in {1..5}
do
  echo "Standard Test #$i"
  
  # Sign text file
  sign_file "$TEXT_FILE" "$SIGNATURE_FILE" "$RSA_PRIVATE_KEY"

  # Verify the signature
  verify_signature "$TEXT_FILE" "$SIGNATURE_FILE" "$RSA_PUBLIC_KEY"
  
  echo "-----------------------"
done

# Now test with multiple file sizes
echo "Testing with various file sizes..."
hash_file "$TEXT_FILE"
for size in 1M 50M; do
  TEST_FILE="$TEST_FILES_DIR/test_$size.bin"
  SIZE_SPECIFIC_SIGNATURE="$TEST_FILES_DIR/signature_${size}.bin"
  
  echo "Testing with file size: $size"
  
  # Calculate hash only (separate from signing)
  hash_file "$TEST_FILE"
  
  # Sign the file
  sign_file "$TEST_FILE" "$SIZE_SPECIFIC_SIGNATURE" "$RSA_PRIVATE_KEY"
  
  # Verify the signature
  verify_signature "$TEST_FILE" "$SIZE_SPECIFIC_SIGNATURE" "$RSA_PUBLIC_KEY"
  
  echo "Completed test for file size: $size"
  echo "-----------------------"
done

# Compare signature sizes if Dilithium signatures are available
if [ -f "/opt/testfiles/dilithium_signature.bin" ] && [ -f "/opt/testfiles/rsa_signature.bin" ]; then
  echo "Comparing RSA and Dilithium signature sizes:" | tee -a "$SIZE_COMPARISON_LOG"
  echo "RSA signature: $(ls -la /opt/testfiles/rsa_signature.bin | awk '{print $5}') bytes" | tee -a "$SIZE_COMPARISON_LOG"
  echo "Dilithium signature: $(ls -la /opt/testfiles/dilithium_signature.bin | awk '{print $5}') bytes" | tee -a "$SIZE_COMPARISON_LOG"
  echo "Size ratio (Dilithium/RSA): $(echo "scale=2; $(ls -la /opt/testfiles/dilithium_signature.bin | awk '{print $5}') / $(ls -la /opt/testfiles/rsa_signature.bin | awk '{print $5}')" | bc)" | tee -a "$SIZE_COMPARISON_LOG"
fi

# Calculate and print average times
echo "Calculating average times..."
SIGN_AVG=$(grep "real" "$SIGN_TIME_LOG" | awk -F"m" '{sum += $2; count++} END {print sum/count}' | sed 's/s//')
VERIFY_AVG=$(grep "real" "$VERIFY_TIME_LOG" | awk -F"m" '{sum += $2; count++} END {print sum/count}' | sed 's/s//')
HASH_AVG=$(grep "real" "$HASH_TIME_LOG" | awk -F"m" '{sum += $2; count++} END {print sum/count}' | sed 's/s//')

echo "Average signing time: ${SIGN_AVG}s"
echo "Average verification time: ${VERIFY_AVG}s"
echo "Average hash calculation time: ${HASH_AVG}s"
echo "Pure signing time (minus hashing): $(echo "$SIGN_AVG - $HASH_AVG" | bc)s"

echo "Testing completed. All logs saved."