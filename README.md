# WPA Supplicant OpenWRT
How to enable wpa_supplicant for AT&amp;T using OpenWRT and bypass the modem/router

- ##  Overview
This is a guide on how to bypass the AT&T Modem/Router using OpenWRT and wpa_supplicant. This method involves having a exploitabled modem such as the BGW210-700. A guide on how to do this is located here [EXPLOIT](https://github.com/bypassrg/att "EXPLOIT"). After extracting and decrypting certificates we upload them to your OpenWRT router.  Download wpa_supplicant package, make init.d script to run on start up.

- ## Requirements
Exploitable Modem
OpenWRT router with wpa_supplicant package
WinSCP software
SSH client such as Putty

**1. Extract Certificates and Decode them with tutorial**

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

`nano /etc/init.d/wpa_supplicant`

Inside nano file add the following lines

```bash
#!/bin/sh /etc/rc.common
START=99
start() {
	echo start
	wpa_supplicant -D wired -i eth1 -c /etc/config/wpa_supplicant.conf
}

```

Make sure to replcace "eth1" with whatever interface you are using.

Run this command to enable startup and start service.

```bash
/etc/init.d/wpa_supplicant enable
/etc/init.d/wpa_supplicant start
```

You should be able to get an ip address from your ONT after running commands.

**6. Make a hotplug scrpit to run when interface goes down**

Make a file called 99-wankeepalive /etc/hotplug.d/iface
`nano /etc/hotplug.d/iface/99-wankeepalive`

Add these few lines of code to 99-wankeepalive

```bash
if [ "$ACTION" = "ifdown" -a "$INTERFACE" = "wan" ]; then

  /etc/wancheck

fi
```

Now make make a wancheck file in /etc/wancheck

`nano /etc/wancheck`

Add these lines of code to wancheck

```bash
#!/bin/sh

COUNTER=0
PASS=0

while [ $PASS -eq 0 ]
do
  grep "unknown" /sys/class/net/eth1/operstate
  RESULT="$?"
  logger -t DEBUG "The wan first check is ${RESULT}"
  
  if [ "$RESULT" != 0 ]; then
    sleep 10 #sec
    grep "unknown" /sys/class/net/eth1/operstate > /dev/null
    RESULT="$?"
    logger -t DEBUG "The wan second check is ${RESULT}"

    if [ "$RESULT" != 0 ]; then

      let COUNTER++
      logger -t DEBUG "Attempt #${COUNTER} to reconnect wan"
  
      ifup wan
      sleep 30 #sec

    else
      PASS=1
      logger -t DEBUG "The wan is connected"
      wpa_supplicant -D wired -i eth1 -c /etc/config/wpa_supplicant.conf
    fi
      
  else
    PASS=1
    logger -t DEBUG "The wan is connected"
    wpa_supplicant -D wired -i eth1 -c /etc/config/wpa_supplicant.conf
  fi
done
```

The code above will check the state of the ethernet interface and loop if it doesnt not find conncection. If it does find a connection the interface will run the wpa_suplicant command to get an ip from AT&T
