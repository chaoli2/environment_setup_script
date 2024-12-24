#!/bin/bash
apt install -y unzip ufw
curl --noproxy certificates.intel.com -k https://certificates.intel.com/repository/certificates/TrustBundles/IntelSHA384TrustChain-Base64.zip -o IntelSHA384TrustChain-Base64.zip
curl --noproxy certificates.intel.com -k https://certificates.intel.com/repository/certificates/IntelSHA2RootChain-Base64.zip -o IntelSHA2RootChain-Base64.zip

mkdir -p  /usr/local/share/ca-certificates

unzip ~/"IntelRootCertificateChainBase64.zip" -d /usr/local/share/ca-certificates
unzip ~/"IntelSHA2RootChain-Base64.zip" -d /usr/local/share/ca-certificates
unzip ~/"IntelSHA384TrustChain-Base64.zip" -d /usr/local/share/ca-certificates

update-ca-certificates
c_rehash

# wget -4 -e use_proxy=no  https://isscorp.intel.com/IntelSM_BigFix/21074/All_BigFix_Client_Installers/Non_Windows/bigfix_non_windows-BESClient_Labs_Prod-TLS.sh
wget --no-check-certificate https://isscorp.intel.com/IntelSM_BigFix/21074/All_BigFix_Client_Installers/Non_Windows/bigfix_non_windows-BESClient_Labs_Prod-TLS.sh
chmod 744 bigfix_non_windows-BESClient_Labs_Prod-TLS.sh
./bigfix_non_windows-BESClient_Labs_Prod-TLS.sh
