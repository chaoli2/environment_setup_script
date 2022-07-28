#!/bin/bash
wget http://certificates.intel.com/repository/certificates/Intel%20Root%20Certificate%20Chain%20Base64.zip
wget http://certs.intel.com/crt/IntelSHA2RootChain-Base64.zip

mkdir -p  /usr/local/share/ca-certificates

unzip "Intel Root Certificate Chain Base64.zip" -d /usr/local/share/ca-certificates
unzip "IntelSHA2RootChain-Base64.zip" -d /usr/local/share/ca-certificates

update-ca-certificates
c_rehash
