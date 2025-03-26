#!/bin/bash
cd /opt/openssl/bin
# Configuration
OUTPUT_DIR="/opt/testfiles/test_logs/key_generation_test"
LOG_FILE="$OUTPUT_DIR/key_generation_times.log"
SUMMARY_FILE="$OUTPUT_DIR/key_generation_summary.txt"

# RSA key sizes to test
RSA_KEY_SIZES=(2048 4096)

# Dilithium variants to test (if available in your OQS installation)
DILITHIUM_VARIANTS=("dilithium3" "dilithium5")

# Number of tests to run for each key type/size
NUM_TESTS=10

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Clear previous logs
> "$LOG_FILE"
> "$SUMMARY_FILE"

echo "Starting key generation benchmark tests..." | tee -a "$LOG_FILE"
echo "===============================================" | tee -a "$LOG_FILE"

# Function to generate RSA keys and measure time
test_rsa_key_generation() {
    key_size=$1
    
    echo "Testing RSA-$key_size key generation ($NUM_TESTS iterations)..." | tee -a "$LOG_FILE"
    echo "RSA-$key_size key generation times (seconds):" >> "$SUMMARY_FILE"
    
    for i in $(seq 1 $NUM_TESTS); do
        echo "  Test #$i for RSA-$key_size" | tee -a "$LOG_FILE"
        start_time=$(python3 -c "import time; print(time.time())")
        openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:$key_size -out "$OUTPUT_DIR/rsa_${key_size}_${i}.key" 2>/dev/null
        end_time=$(python3 -c "import time; print(time.time())")
        file_size=$(stat -c %s "$OUTPUT_DIR/rsa_${key_size}_${i}.key")
        duration=$(echo "$end_time - $start_time" | bc)
        echo "    Time: $duration seconds" | tee -a "$LOG_FILE"
        echo "    Start Time: $start_time" | tee -a "$LOG_FILE"
        echo "    End Time: $end_time seconds" | tee -a "$LOG_FILE"
        echo "    File Size: $file_size bytes" | tee -a "$LOG_FILE"
        echo "$duration" >> "$SUMMARY_FILE"
        
        # Remove the generated key to save space
        rm "$OUTPUT_DIR/rsa_${key_size}_${i}.key"
    done
    
    # Calculate average time
    # avg_time=$(awk '{ total += $1; count++ } END { print total/count }' "$SUMMARY_FILE")
    # echo "Average time for RSA-$key_size: $avg_time seconds" | tee -a "$LOG_FILE" "$SUMMARY_FILE"
    echo "-----------------------------------------------" | tee -a "$LOG_FILE" "$SUMMARY_FILE"
}

# Function to generate Dilithium keys and measure time
test_oqs_key_generation() {
    variant=$1
    
    echo "Testing $variant key generation ($NUM_TESTS iterations)..." | tee -a "$LOG_FILE"
    echo "$variant key generation times (seconds):" >> "$SUMMARY_FILE"
    
    for i in $(seq 1 $NUM_TESTS); do
        echo "  Test #$i for $variant" | tee -a "$LOG_FILE"
        start_time=$(python3 -c "import time; print(time.time())")
        openssl genpkey -algorithm $variant -out "$OUTPUT_DIR/${variant}_${i}.key" \
            -provider oqsprovider 2>/dev/null
        end_time=$(python3 -c "import time; print(time.time())")
        file_size=$(stat -c %s "$OUTPUT_DIR/${variant}_${i}.key")
        duration=$(echo "$end_time - $start_time" | bc)
        echo "    Time: $duration seconds" | tee -a "$LOG_FILE"
        echo "    Start Time: $start_time" | tee -a "$LOG_FILE"
        echo "    End Time: $end_time seconds" | tee -a "$LOG_FILE"
        echo "    File Size: $file_size bytes" | tee -a "$LOG_FILE"
        echo "$duration" >> "$SUMMARY_FILE"
        
        # Remove the generated key to save space
        rm "$OUTPUT_DIR/${variant}_${i}.key"
    done
    
    # Calculate average time
    # avg_time=$(awk '{ total += $1; count++ } END { print total/count }' "$SUMMARY_FILE")
    # echo "Average time for $variant: $avg_time seconds" | tee -a "$LOG_FILE" "$SUMMARY_FILE"
    echo "-----------------------------------------------" | tee -a "$LOG_FILE" "$SUMMARY_FILE"
}

# Check if OQS provider is available
if openssl list -providers | grep -q "oqsprovider"; then
    echo "OQS provider is available." | tee -a "$LOG_FILE"
else
    echo "Warning: OQS provider not detected. Dilithium tests may fail." | tee -a "$LOG_FILE"
fi

# Run RSA key generation tests
echo "Running RSA key generation tests..." | tee -a "$LOG_FILE"
for size in "${RSA_KEY_SIZES[@]}"; do
    test_rsa_key_generation $size
done

# Run Dilithium key generation tests
echo "Running Dilithium key generation tests..." | tee -a "$LOG_FILE"
for variant in "${DILITHIUM_VARIANTS[@]}"; do
    # Check if the variant is supported
    if openssl list -public-key-algorithms -provider oqsprovider | grep -q "$variant"; then
        test_oqs_key_generation $variant
    else
        echo "Skipping $variant - not supported in this OQS build" | tee -a "$LOG_FILE" "$SUMMARY_FILE"
    fi
done

# Generate a comparison chart with simple ASCII art
echo "COMPARISON SUMMARY" | tee -a "$SUMMARY_FILE"
echo "===================" | tee -a "$SUMMARY_FILE"

# Extract averages for comparison
echo "Extracting averages for comparison..." | tee -a "$LOG_FILE"
echo "Key Type | Average Generation Time (s)" | tee -a "$SUMMARY_FILE"
echo "---------|--------------------------" | tee -a "$SUMMARY_FILE"

for size in "${RSA_KEY_SIZES[@]}"; do
    avg=$(grep "Average time for RSA-$size" "$LOG_FILE" | awk '{print $5}')
    echo "RSA-$size | $avg" | tee -a "$SUMMARY_FILE"
done

for variant in "${DILITHIUM_VARIANTS[@]}"; do
    if grep -q "Average time for $variant" "$LOG_FILE"; then
        avg=$(grep "Average time for $variant" "$LOG_FILE" | awk '{print $5}')
        echo "$variant | $avg" | tee -a "$SUMMARY_FILE"
    fi
done

echo "Benchmark complete. Results saved to $SUMMARY_FILE" | tee -a "$LOG_FILE"

# Optional: Generate additional test for key pair operations
echo "Would you like to test key pair generation (key + cert)? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Testing full key pair generation (including certificates)..." | tee -a "$LOG_FILE" "$SUMMARY_FILE"
    echo "=========================================================" | tee -a "$LOG_FILE" "$SUMMARY_FILE"
    
    # RSA key pair test
    echo "Testing RSA-2048 key pair generation..." | tee -a "$LOG_FILE" "$SUMMARY_FILE"
    start_time=$(date +%s%N)
    
    # Generate private key
    openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$OUTPUT_DIR/rsa_pair.key" 2>/dev/null
    
    # Generate self-signed certificate
    openssl req -new -x509 -key "$OUTPUT_DIR/rsa_pair.key" -out "$OUTPUT_DIR/rsa_pair.crt" \
        -subj "/CN=RSA Test Certificate" -days 365 2>/dev/null
    
    end_time=$(date +%s%N)
    duration=$(echo "$end_time - $start_time" | bc)
    echo "RSA-2048 key pair generation time: $duration seconds" | tee -a "$LOG_FILE" "$SUMMARY_FILE"
    
    # Dilithium key pair test
    echo "Testing dilithium2 key pair generation..." | tee -a "$LOG_FILE" "$SUMMARY_FILE"
    start_time=$(date +%s%N)
    
    # Generate private key
    openssl genpkey -algorithm dilithium2 -out "$OUTPUT_DIR/dilithium_pair.key" \
        -provider default -provider oqsprovider 2>/dev/null
    
    # Generate self-signed certificate
    openssl req -new -x509 -key "$OUTPUT_DIR/dilithium_pair.key" -out "$OUTPUT_DIR/dilithium_pair.crt" \
        -subj "/CN=Dilithium Test Certificate" -days 365 \
        -provider default -provider oqsprovider 2>/dev/null
    
    end_time=$(date +%s%N)
    duration=$(echo "$end_time - $start_time" | bc)
    echo "dilithium2 key pair generation time: $duration seconds" | tee -a "$LOG_FILE" "$SUMMARY_FILE"
    
    # Cleanup
    rm "$OUTPUT_DIR/rsa_pair.key" "$OUTPUT_DIR/rsa_pair.crt" 
    rm "$OUTPUT_DIR/dilithium_pair.key" "$OUTPUT_DIR/dilithium_pair.crt"
fi

echo "All tests completed."