#!/usr/bin/env bash

# replace geodata source
. $(dirname $0)/../extra-files/update-geodata.sh

# ==========================================
# 1. Include Custom Package from Source
# ==========================================
# نسخ الإضافة مباشرة إلى مجلد الحزم الأساسي لضمان تعرف النظام عليها
mkdir -p package/
cp -r $(dirname $0)/../luci-app-vlanwizard package/

# ==========================================
# 2. Add Argon Background
# ==========================================
mkdir -p package/base-files/files/www/luci-static/argon/background
cp $(dirname $0)/../bg.jpg package/base-files/files/www/luci-static/argon/background/background.jpg

# ==========================================
# 3. Basic System Settings (Hostname, SSID, Language)
# ==========================================
mkdir -p package/base-files/files/etc/uci-defaults
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-set-basic-settings
#!/bin/sh

# Set Hostname
uci set system.@system[0].hostname='PROMAX'

# Set WiFi SSID
uci set wireless.default_radio0.ssid='PROMAX'
uci set wireless.default_radio1.ssid='PROMAX'

# Force English Language
uci set luci.main.lang='en'

# Save changes
uci commit system
uci commit wireless
uci commit luci
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-set-basic-settings

# ==========================================
# 4. Force WiFi TX Power to 38 dBm (Visual Only)
# ==========================================
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-set-txpower
#!/bin/sh
sleep 15
# Force UI to display 38 dBm (Hardware will limit actual power)
uci set wireless.radio0.txpower='38'
uci set wireless.radio0.txpower_override='1'
uci set wireless.radio1.txpower='38'
uci set wireless.radio1.txpower_override='1'
uci commit wireless
wifi reload
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-set-txpower

# ==========================================
# 5. Set Country Code for WiFi Channels
# ==========================================
# Change 'US' to your preferred country code if needed
sed -i 's/option country.*/option country '\''US'\''/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh

# ==========================================
# 6. Force both LEDs to stay on
# ==========================================
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-force-leds-on
#!/bin/sh
# Blue LED
uci set system.led_sys_blue=led
uci set system.led_sys_blue.name='sys_blue'
uci set system.led_sys_blue.sysfs='blue:status'
uci set system.led_sys_blue.trigger='default-on'

# Yellow LED
uci set system.led_sys_yellow=led
uci set system.led_sys_yellow.name='sys_yellow'
uci set system.led_sys_yellow.sysfs='yellow:status'
uci set system.led_sys_yellow.trigger='default-on'

uci commit system
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-force-leds-on

# ==========================================
# 7. Disable SSH Completely
# ==========================================
sed -i 's/^.*Port.*/Port 22\n#/' package/network/services/dropbear/files/dropbear.config
uci set dropbear.@dropbear[0].Enable='0'

# ==========================================
# 8. Enable OpenVPN service
# ==========================================
/etc/init.d/openvpn enable
