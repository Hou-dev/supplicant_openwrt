# WPA Supplicant OpenWRT
How to enable wpa_supplicant for AT&amp;T using OpenWRT and bypass the modem/router

- ##  Overview
This is a guide on how to bypass the AT&T Modem/Router using OpenWRT and wpa_supplicant. This method involves having a exploitabled modem such as the BGW210-700. A guide on how to do this is located here [EXPLOIT](https://github.com/bypassrg/att "EXPLOIT"). After extracting and decrypting certificated we upload them to your OpenWRT router.  Download wpa_supplicant package, make init.d script to run on start up.

- ## Requirements
Exploitable Modem
OpenWRT router with wpa_supplicant package
WinSCP software
SSH client such as Putty

1. Extract Certificates and Decode them with tutorial.

2. Download wpa_supplicant package by using these commands
`opkg update`
`opkg install wpa_supplicant`

or alternatively you can download the ipk from the OpenWRT ftp server. but make sure have the correct target and release. For example mine is x86 with 21.02.0 release.
[https://downloads.openwrt.org/releases/21.02.0/packages/x86_64/packages/](https://downloads.openwrt.org/releases/21.02.0/packages/x86_64/packages/)
