#!/usr/bin/env bash

# ==========================================
# 1. تعيين اسم الجهاز (Hostname)
# ==========================================
sed -i 's/OpenWrt/PROMAX/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/PROMAX/g' package/base-files/files/bin/config_generate

# ==========================================
# 2. إعدادات الواي فاي الافتراضية (تفعيل الراديو)
# ==========================================
WIFI_FILE="package/kernel/mac80211/files/lib/wifi/mac80211.sh"
if [ -f "$WIFI_FILE" ]; then
    sed -i 's/disabled=1/disabled=0/g' "$WIFI_FILE"
fi

# ==========================================
# 3. إعدادات وضع الـ Access Point والدولة (بنما) - بدون VLAN وبدون Gateway
# ==========================================
mkdir -p package/base-files/files/etc/uci-defaults
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-set-ap-mode
#!/bin/sh

# 1. حذف واجهات الـ WAN تماماً وإبقاء LAN فقط
uci delete network.wan 2>/dev/null || true
uci delete network.wan6 2>/dev/null || true

# 2. تعطيل خدمة DHCP على واجهة LAN (لأن الميكروتك هو من سيوفر العناوين)
uci set dhcp.lan.ignore='1'
uci set dhcp.lan.dynamicdhcp='0'

# 3. تعطيل خدمات IPv6
uci set dhcp.lan.ra='disabled'
uci set dhcp.lan.dhcpv6='disabled'
uci set dhcp.lan.ndp='disabled'

# 4. تعيين عنوان IP ثابت للجهاز (بدون Gateway - ستقوم بإعداده يدوياً لكل جهاز)
uci set network.lan.proto='static'
uci set network.lan.ipaddr='192.168.1.21'
uci set network.lan.netmask='255.255.255.0'
uci delete network.lan.gateway 2>/dev/null || true

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

# 7. تعيين اسم الشبكة (SSID) وكلمة المرور (بدون كلمة مرور)
uci set wireless.default_radio0.ssid='promax'
uci set wireless.default_radio0.encryption='none'

if uci get wireless.default_radio1 >/dev/null 2>&1; then
    uci set wireless.default_radio1.ssid='promax_5G'
    uci set wireless.default_radio1.encryption='none'
fi

# حفظ التغييرات
uci commit dhcp
uci commit network
uci commit wireless
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-set-ap-mode

# ==========================================
# 4. نسخ إضافة luci-app-quicksetup (دمج الحزمة)
# ==========================================
if [ -d "$GITHUB_WORKSPACE/luci-app-quicksetup" ]; then
    echo "جاري نسخ إضافة luci-app-quicksetup..."
    cp -r "$GITHUB_WORKSPACE/luci-app-quicksetup" package/
else
    echo "خطأ: لم يتم العثور على مجلد luci-app-quicksetup!"
fi

# ==========================================
# 5. حقن قيم طاقة اللاسلكي الوهمية حتى 40 dBm
# ==========================================
WIRELESS_JS=$(find . -name "wireless.js" -path "*network*" 2>/dev/null | head -n 1)

if [ -n "$WIRELESS_JS" ] && [ -f "$WIRELESS_JS" ]; then
    echo "تم العثور على wireless.js في: $WIRELESS_JS"
    
    # محاولة الحقن للإصدارات الحديثة (for...of)
    if grep -q "for(let p of pwrlist)" "$WIRELESS_JS"; then
        sed -i "s|for(let p of pwrlist)|for(let i=27; i<=40; i++) { pwrlist.push({dbm: i, mw: Math.round(Math.pow(10, (i-30)/10) * 1000)}); }; pwrlist = pwrlist.filter((v,i,a)=>a.findIndex(t=>(t.dbm===v.dbm))===i); for(let p of pwrlist)|g" "$WIRELESS_JS"
        echo "✅ تم حقن القيم للإصدار الحديث."
    
    # الحقن للإصدارات القديمة (for(var i=...))
    elif grep -q "for(var i=0;i<pwrlist.length;i++)" "$WIRELESS_JS"; then
        sed -i "s|for(var i=0;i<pwrlist.length;i++)|for(let j=27; j<=40; j++) { pwrlist.push({dbm: j, mw: Math.round(Math.pow(10, (j-30)/10) * 1000)}); }; pwrlist = pwrlist.filter((v,i,a)=>a.findIndex(t=>(t.dbm===v.dbm))===i); for(var i=0;i<pwrlist.length;i++)|g" "$WIRELESS_JS"
        echo "✅ تم حقن القيم للإصدار القديم."
    else
        echo "⚠️ لم يتم العثور على النمط المناسب لحقن القيم."
    fi
else
    echo "⚠️ لم يتم العثور على ملف wireless.js."
fi

# ==========================================
# 6. تعطيل الخدمات غير الضرورية (مع إبقاء SSH يعمل)
# ==========================================
cat << 'EOF' > package/base-files/files/etc/uci-defaults/98-disable-router-services
#!/bin/sh
/etc/init.d/firewall disable 2>/dev/null || true
/etc/init.d/eoip disable 2>/dev/null || true
/etc/init.d/mwan3 disable 2>/dev/null || true
/etc/init.d/odhcpd disable 2>/dev/null || true
/etc/init.d/log disable 2>/dev/null || true
/etc/init.d/dnsmasq disable 2>/dev/null || true
# ملاحظة: خدمة dropbear (SSH) لم يتم تعطيلها، ستبقى تعمل في الخلفية
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/98-disable-router-services

# ==========================================
# 7. إخفاء خيارات SSH و HTTP و Backup من واجهة LuCI
# ==========================================
# إخفاء خيارات SSH و HTTP من صفحة Administration
ADMIN_JS=$(find . -name "admin.js" -path "*luci-mod-system*" 2>/dev/null | head -n 1)
if [ -n "$ADMIN_JS" ] && [ -f "$ADMIN_JS" ]; then
    echo "✅ تم العثور على admin.js، جاري إخفاء خيارات SSH و HTTP..."
    sed -i "s|var s = m.section(form.NamedSection, 'dropbear', 'dropbear')|/* Hidden */ /* var s = m.section(form.NamedSection, 'dropbear', 'dropbear') */|g" "$ADMIN_JS"
    sed -i "s|var s = m.section(form.NamedSection, 'keys', 'system')|/* Hidden */ /* var s = m.section(form.NamedSection, 'keys', 'system') */|g" "$ADMIN_JS"
    sed -i "s|var s = m.section(form.NamedSection, 'http', 'uhttpd')|/* Hidden */ /* var s = m.section(form.NamedSection, 'http', 'uhttpd') */|g" "$ADMIN_JS"
else
    echo "⚠️ لم يتم العثور على admin.js"
fi

# إخفاء خيارات Backup و Configuration من صفحة Flash
FLASH_JS=$(find . -name "flash.js" -path "*luci-mod-system*" 2>/dev/null | head -n 1)
if [ -n "$FLASH_JS" ] && [ -f "$FLASH_JS" ]; then
    echo "✅ تم العثور على flash.js، جاري إخفاء خيارات Backup و Configuration..."
    sed -i "s|var backup = s.taboption('backup', form.FileUpload, 'backup')|/* Hidden */ /* var backup = s.taboption('backup', form.FileUpload, 'backup') */|g" "$FLASH_JS"
    sed -i "s|var config = s.taboption('config', form.DummyValue, '_config')|/* Hidden */ /* var config = s.taboption('config', form.DummyValue, '_config') */|g" "$FLASH_JS"
else
    echo "⚠️ لم يتم العثور على flash.js"
fi
