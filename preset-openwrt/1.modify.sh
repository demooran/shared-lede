#!/usr/bin/env bash

# modify login IP
#sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate

# copy uci-defaults script(s)
mkdir -p files/etc/uci-defaults
cp $(dirname $0)/uci-scripts/* files/etc/uci-defaults/

# modify default package(s)
if ! grep -q "dnsmasq-full" include/target.mk; then
    sed -i 's/dnsmasq/dnsmasq-full/g' include/target.mk
fi

# modify luci-app-xray category
modify_lax_category() {
    local mk=$1
    [ -e $mk ] || return
    sed -i 's/SECTION:=Custom/CATEGORY:=LuCI/g' $mk
    sed -i 's/CATEGORY:=Extra packages/SUBMENU:=3. Applications/g' $mk
}
modify_lax_category 'package/feeds/supply/luci-app-xray-core/Makefile'
modify_lax_category 'package/feeds/supply/luci-app-xray-status/Makefile'

# replace geodata source
. $(dirname $0)/../extra-files/update-geodata.sh
# Change Hostname to PROMAX
    sed -i 's/OpenWrt/PROMAX/g' package/base-files/files/bin/config_generate
# Add Argon Background
mkdir -p package/base-files/files/www/luci-static/argon/background
cp $(dirname $0)/../bg.jpg package/base-files/files/www/luci-static/argon/background/background.jpg

# Install Custom IPK
# Install Custom IPK
mkdir -p package/base-files/files/tmp
cp $(dirname $0)/../luci-app-vlanwizard_1.0_all.ipk package/base-files/files/tmp/
echo "opkg install /tmp/luci-app-vlanwizard_1.0_all.ipk" >> package/base-files/files/etc/rc.local

# ==========================================
# 9. Configure LAN for Access Point Mode (Disable DHCP)
# ==========================================
cat <<  EOF  > package/base-files/files/etc/uci-defaults/99-set-ap-mode
#!/bin/sh

# 1. Disable DHCP Server on LAN
uci set dhcp.lan.ignore= 1 

# 2. Disable Dynamic DHCP (Advanced Settings)
uci set dhcp.lan.dynamicdhcp= 0 

# 3. Disable IPv6 RA and DHCPv6 Services
uci set dhcp.lan.ra= disabled 
uci set dhcp.lan.dhcpv6= disabled 
uci set dhcp.lan.ndp= disabled 

# Save changes
uci commit dhcp
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-set-ap-mode
