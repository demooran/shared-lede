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
# 5. إعدادات وضع الـ Access Point والدولة (بنما) وحذف WAN
# ==========================================
mkdir -p package/base-files/files/etc/uci-defaults
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-set-ap-mode
#!/bin/sh

# 1. حذف واجهات الـ WAN تماماً وإبقاء LAN فقط
uci delete network.wan 2>/dev/null || true
uci delete network.wan6 2>/dev/null || true

# 2. تعطيل خدمة DHCP على واجهة LAN
uci set dhcp.lan.ignore='1'
uci set dhcp.lan.dynamicdhcp='0'

# 3. تعطيل خدمات IPv6
uci set dhcp.lan.ra='disabled'
uci set dhcp.lan.dhcpv6='disabled'
uci set dhcp.lan.ndp='disabled'

# 4. تعيين عنوان IP ثابت للجهاز (بوابة الراوتر الرئيسي)
uci set network.lan.proto='static'
uci set network.lan.ipaddr='192.168.1.21'
uci set network.lan.netmask='255.255.255.0'

# 5. تعيين الدولة إلى بنما (PA)
uci set wireless.radio0.country='PA'
if uci get wireless.radio1 >/dev/null 2>&1; then
    uci set wireless.radio1.country='PA'
fi

# 6. إعدادات الواي فاي (عزل العملاء وإلغاء الفصل التلقائي)
uci set wireless.default_radio0.isolate='1'
uci set wireless.default_radio0.disassoc_low_ack='0'
if uci get wireless.default_radio1 >/dev/null 2>&1; then
    uci set wireless.default_radio1.isolate='1'
    uci set wireless.default_radio1.disassoc_low_ack='0'
fi

# حفظ التغييرات
uci commit dhcp
uci commit network
uci commit wireless
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-set-ap-mode

# ==========================================
# 7. حقن قيم طاقة اللاسلكي الوهمية حتى 40 dBm في السورس
# ==========================================
WIRELESS_JS=$(find . -path "*/luci-app-wireless/htdocs/luci-static/resources/view/network/wireless.js" -o -path "*/luci-mod-network/htdocs/luci-static/resources/view/network/wireless.js" 2>/dev/null | head -n 1)

if [ -n "$WIRELESS_JS" ] && [ -f "$WIRELESS_JS" ]; then
    sed -i '/callTXPowerlist/a \            for(let i=27; i<=40; i++) pwrlist.push({dbm: i, mw: Math.round(Math.pow(10, (i-30)/10) * 1000)});\
            pwrlist = pwrlist.filter((v,i,a)=>a.findIndex(t=>(t.dbm===v.dbm))===i);' "$WIRELESS_JS"
fi

# ==========================================
# 8. نسخ إضافة luci-app-quicksetup (دمج الحزمة)
# ==========================================
if [ -d "$GITHUB_WORKSPACE/luci-app-quicksetup" ]; then
    cp -r "$GITHUB_WORKSPACE/luci-app-quicksetup" package/
fi

# ==========================================
# 9. تعطيل الخدمات غير الضرورية
# ==========================================
cat << 'EOF' > package/base-files/files/etc/uci-defaults/98-disable-router-services
#!/bin/sh
/etc/init.d/firewall disable 2>/dev/null || true
/etc/init.d/eoip disable 2>/dev/null || true
# /etc/init.d/mesh11sd disable 2>/dev/null || true
/etc/init.d/mwan3 disable 2>/dev/null || true
/etc/init.d/odhcpd disable 2>/dev/null || true
# /etc/init.d/radius disable 2>/dev/null || true
/etc/init.d/log disable 2>/dev/null || true
/etc/init.d/dnsmasq disable 2>/dev/null || true
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/98-disable-router-services
