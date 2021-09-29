# WPA Supplicant OpenWRT
How to enable wpa_supplicant for AT&amp;T using OpenWRT and bypass the modem/router

- ##  Overview
This is a guide on how to bypass the AT&T Modem/Router using OpenWRT and wpa_supplicant. This method involves having a exploitabled modem such as the BGW210-700. A guide on how to do this is located here [EXPLOIT](https://github.com/bypassrg/att "EXPLOIT"). After extracting and decrypting certificates we upload them to your OpenWRT router.  Download wpa_supplicant package, make init.d script to run on start up.

- ## Requirements
Exploitable Modem
OpenWRT router with wpa_supplicant package
WinSCP software
SSH client such as Putty

**1. Extract Certificates and Decode them with tutorial.**
You should have four files that are important for wpa_supplicant such as a ca_xxxx.pem , cleint_xxx.pem, privatekey_xxxx.pem and wpa_supplicant.conf

**2. Download wpa_supplicant package by using these commands**

```bash
opkg update
opkg install wpa_supplicant
```

or alternatively you can download the ipk from the OpenWRT ftp server. but make sure have the correct target and release. For example mine is x86 with 21.02.0 release
[https://downloads.openwrt.org/releases/21.02.0/packages/x86_64/packages/](https://downloads.openwrt.org/releases/21.02.0/packages/x86_64/packages/)

**3. Make a directory in OpenWRT /etc/config folder called auth**
`mkdir /etc/config/auth`
Now place the ca_xxxx.pem , cleint_xxx.pem and privatekey_xxxx.pem into the auth folder

**4. Place your wpa_supplicant.conf in /etc/config folder and edit it using vim**
You can move it there from the commandline or using WinSCP.
Edit the wpa_supplicant file to reflect the directory of the certs. ie. /etc/config/auth

```bash
eapol_version=1
ap_scan=0
fast_reauth=1
network={
        ca_cert="/etc/config/auth/CA_XXXX.pem"
        client_cert="/etc/config/auth/Client_XXXX.pem"
        eap=TLS
        eapol_flags=0
        identity="XX:XX:XX:XX:XX:XX" # Internet (ONT) interface MAC address must match this value
        key_mgmt=IEEE8021X
        phase1="allow_canned_success=1"
        private_key="/etc/config/auth/PrivateKey_XXXX.pem"
}

```
**5. Make inint.d script to run at startup**
