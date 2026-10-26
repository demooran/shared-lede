#!/usr/bin/env bash

# replace geodata source
. $(dirname $0)/../extra-files/update-geodata.sh

# 1. Change Hostname and SSID (Using uci-defaults for guaranteed execution on boot)
mkdir -p package/base-files/files/etc/uci-defaults
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-set-custom-name
#!/bin/sh
uci set system.@system[0].hostname='PROMAX'
uci set wireless.default_radio0.ssid='PROMAX'
uci set wireless.default_radio1.ssid='PROMAX'
uci commit system
uci commit wireless
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-set-custom-name

# 2. Add Argon Background
mkdir -p package/base-files/files/www/luci-static/argon/background
cp $(dirname $0)/../bg.jpg package/base-files/files/www/luci-static/argon/background/background.jpg

# 3. Include Custom Package from Source
mkdir -p package/custom-packages
cp -r $(dirname $0)/../luci-app-vlanwizard package/custom-packages/

# 4. Force WiFi TX Power (This is handled safely, though hardware will limit it)
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-set-txpower
#!/bin/sh
sleep 10
uci set wireless.radio0.txpower='38'
uci set wireless.radio1.txpower='35'
uci commit wireless
wifi reload
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-set-txpower

# 5. Force both LEDs to stay on from boot
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-force-leds-on
#!/bin/sh
uci set system.led_sys_blue=led
uci set system.led_sys_blue.name='sys_blue'
uci set system.led_sys_blue.sysfs='blue:status'
uci set system.led_sys_blue.trigger='default-on'

uci set system.led_sys_yellow=led
uci set system.led_sys_yellow.name='sys_yellow'
uci set system.led_sys_yellow.sysfs='yellow:status'
uci set system.led_sys_yellow.trigger='default-on'

uci commit system
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-force-leds-on

# 6. Set Country Code to US (for maximum allowed power)
sed -i 's/option country.*/option country '\''US'\''/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh

# 7. Disable SSH Completely (Port change + Service Disable)
sed -i 's/^.*Port.*/Port 22\n#/' package/network/services/dropbear/files/dropbear.config
uci set dropbear.@dropbear[0].Enable='0'

# 8. Enable OpenVPN service
/etc/init.d/openvpn enable

# 9. Hide pages (Backup, Software, SSH) - *Removed to prevent menu breaking*
# I have commented these out because the paths differ in ImmortalWrt 24.10, 
# and deleting them caused the Software menu to disappear entirely.
# If you want to hide them, do it manually via LuCI after installation.
