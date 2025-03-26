# OpenSSL PQC Test Suite

This repository contains scripts and commands for testing OpenSSL with post-quantum cryptography (PQC) support using a dockerized environment bootstrapped with docker compose.

## Prerequisites

Ensure you have OpenSSL installed and properly configured. The scripts assume the presence of OpenSSL binaries in the specified paths. This is designed to work in a docker-compose environment containing four services:

1. Vault - Key Value Vault

2. Pqc Server

3. Pqc Client

4. Pqc Keys Generator

## Usage

### Connect to PQC Server

To establish a secure connection to a PQC-enabled server, from the pqc\_client, you have to run:

```sh
openssl s_client -connect pqc-server:4433 (OQS Server)
openssl s_client -connect pqc-server:4443 (RSA Server)
```

### Update Cryptographic Keys

To update cryptographic keys in the PQC server (this is automated but for testing we can call it on demand), execute inside the pqc-server:

```sh
/usr/local/bin/update-keys.sh
```

### Start OpenSSL Server

To start the OpenSSL server in the PQC-Server, use:

```sh
/opt/openssl/bin/serverstart.sh
```

### Performance Testing

#### RSA Performance Test

To run the RSA performance test:

```sh
/opt/testfiles/perf_test_rsa.sh
```

#### OQS Performance Test

To benchmark the Open Quantum Safe (OQS) implementation:

```sh
/opt/testfiles/perf_test_oqs.sh
```

### Performance Test for Key Creation

To create cryptographic keys, run:

```sh
/opt/testfiles/perf_create_keys.sh
```

## License

This project is licensed under the MIT License.

