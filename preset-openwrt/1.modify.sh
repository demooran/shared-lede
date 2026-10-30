#!/usr/bin/env bash

# ==========================================
# 1. تعيين اسم الجهاز (Hostname)
# ==========================================
sed -i 's/OpenWrt/PROMAX/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/PROMAX/g' package/base-files/files/bin/config_generate

# ==========================================
# 2. استبدال dnsmasq بـ dnsmasq-full
# ==========================================
if ! grep -q "dnsmasq-full" include/target.mk; then
    sed -i 's/dnsmasq/dnsmasq-full/g' include/target.mk
fi

# ==========================================
# 3. إضافة خلفية Argon
# ==========================================
mkdir -p package/base-files/files/www/luci-static/argon/background
if [ -f "$(dirname $0)/../bg.jpg" ]; then
    cp $(dirname $0)/../bg.jpg package/base-files/files/www/luci-static/argon/background/background.jpg
fi

# ==========================================
# 4. إعدادات الواي فاي الافتراضية (SSID)
# ==========================================
WIFI_FILE="package/kernel/mac80211/files/lib/wifi/mac80211.sh"
if [ -f "$WIFI_FILE" ]; then
    sed -i 's/disabled=1/disabled=0/g' "$WIFI_FILE"
    sed -i 's/ssid=OpenWrt/ssid=PROMAX/g' "$WIFI_FILE"
    sed -i 's/ssid=ImmortalWrt/ssid=PROMAX/g' "$WIFI_FILE"
fi

# ==========================================
# 5. إعدادات وضع الـ Access Point والدولة (بنما)
# ==========================================
mkdir -p package/base-files/files/etc/uci-defaults
cat <<  EOF  > package/base-files/files/etc/uci-defaults/99-set-ap-mode
#!/bin/sh

# 1. تعطيل خدمة DHCP على واجهة LAN
uci set dhcp.lan.ignore='1'
uci set dhcp.lan.dynamicdhcp='0'

# 2. تعطيل خدمات IPv6
uci set dhcp.lan.ra='disabled'
uci set dhcp.lan.dhcpv6='disabled'
uci set dhcp.lan.ndp='disabled'

# 3. تعيين عنوان IP ثابت للجهاز (بوابة الراوتر الرئيسي)
uci set network.lan.proto='static'
uci set network.lan.ipaddr='192.168.1.21'
uci set network.lan.netmask='255.255.255.0'
uci set network.lan.gateway='192.168.1.1'
uci set network.lan.dns='192.168.1.1'

# 4. تعيين الدولة إلى بنما (PA)
uci set wireless.radio0.country='PA'
if uci get wireless.radio1 >/dev/null 2>&1; then
    uci set wireless.radio1.country='PA'
fi

# حفظ التغييرات
uci commit dhcp
uci commit network
uci commit wireless
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-set-ap-mode

# ==========================================
# 6. نسخ إضافة vlanwizard (دمج الحزمة)
# ==========================================
# هذا الأمر ينسخ مجلد الحزمة المصدري إلى مجلد الحزم ليقوم النظام ببنائه
if [ -d "$GITHUB_WORKSPACE/luci-app-vlanwizard" ]; then
    cp -r $GITHUB_WORKSPACE/luci-app-vlanwizard package/
fi
