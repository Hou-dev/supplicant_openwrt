#!/bin/sh

# Detect WAN device
wandevice="$(ifstatus wan |  jsonfilter -e '@["device"]')"
if [ "$(opkg list-installed | grep wpa_supplicant 2>/dev/null)" != "" ]; then
	echo -e "Need to install wpa_supplicant!!!\nTry:\n\topkg update\n\topkg install wpa_supplicant"
	exit 1
fi

# Detect Mac Address of WAN
macaddress=$(cat /sys/class/net/$wandevice/address | awk '{print toupper($0)}' )

# Check for Certs, and bail if not found.
for i in /etc/config/auth/*.pem ; do
	if [ "$(echo "$i" | grep CA_ )" != "" ]; then
		ca_cert="$i"
	elif [ "$(echo "$i" | grep Client_ )" != "" ]; then
		client_cert="$i"
	elif [ "$(echo "$i" | grep PrivateKey_ )" != "" ]; then
		private_key="$i"
	fi
done
if [ "$ca_cert" = "" ]; then
	echo -e "ca_cert is not found in /etc/config/auth!!!\nMake sure you have put it in /etc/config/auth.\nIt should be named CA_XXXX.pem, where the XXXX can be anything."
	exit 1
elif [ "$client_cert" = "" ]; then
	echo -e "client_cert is not found in /etc/config/auth!!!\nMake sure you have put it in /etc/config/auth.\nIt should be named Client_XXXX.pem, where the XXXX can be anything."
	exit 1
elif [ "$private_key" = "" ]; then
	echo -e "private_key is not found in /etc/config/auth!!!\nMake sure you have put it in /etc/config/auth.\nIt should be named PrivateKey_XXXX.pem, where the XXXX can be anything."
	exit 1
fi

# Display info
echo -e "Wan device: $wandevice\nMac Address: $macaddress\nca_cert: $ca_cert\nclient_cert: $client_cert\nprivate_key: $private_key\n\n"

# Function that checks if file exists, and renames it with a .old suffix if it does
checkforfile () {
	if [ -e "$1" ]; then
		echo "$1 Found!!! renaming it to $1.old"
		mv "$1" "$1.old"
	fi
}

# Create wpa_supplicant.conf
file="/etc/config/wpa_supplicant.conf"
checkforfile "$file"
cat << EOF > "$file"
eapol_version=1
ap_scan=0
fast_reauth=1
network={
        ca_cert="$ca_cert"
        client_cert="$client_cert"
        eap=TLS
        eapol_flags=0
        identity="${macaddress}" # Internet (ONT) interface MAC address must match this value
        key_mgmt=IEEE8021X
        phase1="allow_canned_success=1"
        private_key="$private_key"
}
EOF
echo "Wrote $file"

# Create init.d for wpa_supplicant
file="/etc/init.d/wpa_supplicant"
checkforfile "$file"
cat << EOF > "$file"
#!/bin/sh /etc/rc.common
# Copyright (C) 2007 OpenWrt.org
START=99
STOP=99
USE_PROCD=1
PROG=/usr/sbin/wpa_supplicant

boot()
{
    rc_procd start_service
}


start_service() {
    procd_open_instance
    # attempt to restart every 30 seconds, the eap proxy for internet connectivity
    procd_set_param respawn \${respawn_threshold:-3600} \${respawn_timeout:-30} \${respawn_retry:-0}
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_set_param command \$PROG
    procd_append_param command -D wired
    procd_append_param command -i ${wandevice}
    procd_append_param command -c /etc/config/wpa_supplicant.conf
    procd_close_instance
}

service_triggers()
{
    procd_add_reload_trigger "network"
}
EOF
chmod +x "$file"
echo "Wrote $file"

# Create keepalive... Don't know if it is realld needed, but included it. Will test without it later.
file="/etc/hotplug.d/iface/99-wankeepalive"
checkforfile "$file"
cat << 'EOF' > "$file"
if [ "$ACTION" = "ifdown" -a "$INTERFACE" = "wan" ]; then
  /etc/wancheck
fi
EOF
echo "Wrote $file"

# Create WanCheck
file="/etc/wancheck"
checkforfile "$file"
cat << EOF > "$file"
#!/bin/sh

COUNTER=0
PASS=0

while [ \$PASS -eq 0 ]
do
  isup=$(cat /sys/class/net/${wandevice}/operstate)
  logger -t DEBUG "The wan first check is \${isup}"

  if [ "\$isup" != "up" ]; then
    sleep 10 #sec
    isup=$(cat /sys/class/net/${wandevice}/operstate)
    logger -t DEBUG "The wan second check is \${isup}"

    if [ "\$isup" != "up" ]; then

      let COUNTER++
      logger -t DEBUG "Attempt #\${COUNTER} to reconnect wan"
      ifup wan
      sleep 5 #sec

    else
      PASS=1
      logger -t DEBUG "The wan is connected"
      /etc/init.d/wpa_supplicant restart
    fi

  else
    PASS=1
    logger -t DEBUG "The wan is connected"
  fi
done
EOF
chmod +x "$file"
echo "Wrote $file"

# Display info for enabling / disabling and uninstall
echo -e "\nFinished!!!!\n\nTo enable, run:\n\t/etc/init.d/wpa_supplicant enable\n\t/etc/init.d/wpa_supplicant start\n\n\nTo uninstall, Run:\n\t/etc/init.d/wpa_supplicant stop\n\t/etc/init.d/wpa_supplicant disable\n\trm /etc/init.d/wpa_supplicant /etc/hotplug.d/iface/99-wankeepalive /etc/wancheck /etc/config/wpa_supplicant.conf"
