#!/usr/bin/env bash

# modify login IP
#sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate

# replace geodata source
. $(dirname $0)/../extra-files/update-geodata.sh

# Change Hostname and SSID via UCI
uci set system.@system[0].hostname='PRO-MAX' 
uci set wireless.default_radio0.ssid='PRO-MAX' 
uci set wireless.default_radio1.ssid='PRO-MAX' 
uci commit system
uci commit wireless

# Add Argon Background
mkdir -p package/base-files/files/www/luci-static/argon/background
cp $(dirname $0)/../bg.jpg package/base-files/files/www/luci-static/argon/background/background.jpg

# Include Custom Package from Source
mkdir -p package/custom-packages
cp -r $(dirname $0)/../luci-app-vlanwizard package/custom-packages/

# 1. إخفاء صفحة النسخ الاحتياطي (Backup / Flash Firmware)
rm -f package/feeds/luci/luci-mod-system/htdocs/luci-static/resources/view/system/backup.js
rm -f package/feeds/luci/luci-mod-system/root/usr/share/luci/menu.d/luci-mod-system-backup.json
rm -f package/feeds/luci/luci-mod-system/root/usr/share/rpcd/acl.d/luci-mod-system-backup.json

# 2. إخفاء صفحة البرامج (Software)
rm -f package/feeds/luci/luci-app-opkg/htdocs/luci-static/resources/view/opkg.js
rm -f package/feeds/luci/luci-app-opkg/root/usr/share/luci/menu.d/luci-app-opkg.json
rm -f package/feeds/luci/luci-app-opkg/root/usr/share/rpcd/acl.d/luci-app-opkg.json

# 3. منع الوصول إلى SSH (SSH Access)
# إزالة صفحة SSH من القائمة (إخفاء زر SSH Keys / Terminal)
rm -f package/feeds/luci/luci-mod-system/htdocs/luci-static/resources/view/system/sshkeys.js
rm -f package/feeds/luci/luci-mod-system/root/usr/share/luci/menu.d/luci-mod-system-sshkeys.json
rm -f package/feeds/luci/luci-mod-system/root/usr/share/rpcd/acl.d/luci-mod-system-sshkeys.json

# تعطيل خدمة SSH تماماً (إذا كنت لا تريد لأحد استخدامها عبر Terminal)
sed -i  's/^.*Port.*/Port 22\n#/'  package/network/services/dropbear/files/dropbear.config
uci set dropbear.@dropbear[0].Enable='0'

# Enable OpenVPN service
/etc/init.d/openvpn enable

# Force WiFi TX Power to 38 dBm
mkdir -p package/base-files/files/etc/uci-defaults
cat <<  EOF  > package/base-files/files/etc/uci-defaults/99-set-txpower
#!/bin/sh
# Wait for radios to initialize
sleep 10
# Set power for 2.4G and 5G
uci set wireless.radio0.txpower='38' 
uci set wireless.radio1.txpower='35' 
uci commit wireless
wifi reload
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-set-txpower

# Set Country Code to US or CN to allow max power
sed -i 's/option country.*/option country '\''US''\''/g'  package/kernel/mac80211/files/lib/wifi/mac80211.sh
