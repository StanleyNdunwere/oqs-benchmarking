curl --header "X-Vault-Token: root" \
     --request POST \
     --data '{"data": {"username": "myuser", "password": "mypassword"}}' \
     --header "X-Vault-TTL: 3600" \
     http://localhost:8200/v1/secret/data/mysecret


     the mysecret is editable others are fixed
     curl --header "X-Vault-Token: root" \
     http://localhost:8200/v1/secret/data/mysecret


     openssl s_client -connect pqc-server:4433


/opt/openssl/bin/serverstart.sh

 /opt/testfiles/perf_test_rsa.sh

 /opt/testfiles/perf_test_oqs.sh

  /opt/testfiles/perf_create_keys.sh

cat /opt/testfiles/test_logs/time-taken-encrypt-rsa.log

cat /opt/testfiles/test_logs/time-taken-encrypt-oqs.log

Test with multiple file sizes in a single run:
bashCopyfor size in 1M 10M 100M 1G; do
  dd if=/dev/urandom of="test_$size.bin" bs=$size count=1
  # Run your timing tests on each file
done

Compare signature sizes: Dilithium signatures are typically much larger than RSA signatures:
bashCopy# After generating signatures
ls -la dilithium_signature.bin rsa_signature.bin


Test key generation time: While not part of signing/verification, key generation should show dramatic differences:
time openssl genpkey -algorithm rsa -out rsa_key.pem
time openssl genpkey -algorithm dilithium3 -out dilithium_key.pem -provider oqsprovider -provider default

oqs - dilithium3
Calculating average times...
Average signing time: 0.01825s
Average verification time: 0.01625s
Average hash calculation time: 0.045s
Pure signing time (minus hashing): -.02675s
Testing completed. All logs saved.

rsa 2048
Calculating average times...
Average signing time: 0.0168269s
Average verification time: 0.0135577s
Average hash calculation time: 0.044s
Pure signing time (minus hashing): -.0271731s
Testing completed. All logs saved.

rsa 4096
Calculating average times...
Average signing time: 0.0259808s
Average verification time: 0.0143558s
Average hash calculation time: 0.04425s
Pure signing time (minus hashing): -.0182692s
Testing completed. All logs saved.


dilithium 5
Calculating average times...
Average signing time: 0.0171154s
Average verification time: 0.0140769s
Average hash calculation time: 0.044s
Pure signing time (minus hashing): -.0268846s
Testing completed. All logs saved.