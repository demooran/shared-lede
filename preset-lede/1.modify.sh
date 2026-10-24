#!/usr/bin/env bash

# modify login IP
#sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate

# Change Hostname and SSID via UCI
uci set system.@system[0].hostname='PROMAX'
uci commit system

# modify device name show
#sed -i 's/Xiaomi Mi Router 4A Gigabit Edition/Xiaomi 4A Gigabit/g' target/linux/ramips/dts/mt7621_xiaomi_mi-router-4a-gigabit.dts
#sed -i 's/Xiaomi Mi Router 3G v2/Xiaomi 3G v2/g' target/linux/ramips/dts/mt7621_xiaomi_mi-router-3g-v2.dts
#sed -i 's/Xiaomi Redmi Router AC2100/Redmi AC2100/g' target/linux/ramips/dts/mt7621_xiaomi_redmi-router-ac2100.dts
#sed -i 's/Xiaomi Mi Router AC2100/Xiaomi AC2100/g' target/linux/ramips/dts/mt7621_xiaomi_mi-router-ac2100.dts
#sed -i 's/Xiaomi Mi Router CR660x/Xiaomi CR660x/g' target/linux/ramips/dts/mt7621_xiaomi_mi-router-cr6606.dts

# copy smartdns configuration
#sed -i 's#$(PKG_BUILD_DIR)/package/openwrt/address.conf#$(CURDIR)/files/address.conf#g' feeds/packages/net/smartdns/Makefile
#sed -i 's#$(PKG_BUILD_DIR)/package/openwrt/files/etc/config/smartdns#$(CURDIR)/files/smartdns#g' feeds/packages/net/smartdns/Makefile
#cp -r $(dirname $0)/../extra-files/smartdns/files feeds/packages/net/smartdns/

# copy uci-defaults script(s)
mkdir -p files/etc/uci-defaults
cp $(dirname $0)/uci-scripts/* files/etc/uci-defaults/

# switch ramips kernel to 5.10
#sed -i '/KERNEL_PATCHVER/cKERNEL_PATCHVER:=5.10' target/linux/ramips/Makefile

# switch ramips kernel to 5.15
#sed -i '/KERNEL_PATCHVER/cKERNEL_PATCHVER:=5.15' target/linux/ramips/Makefile

# copy kernel 5.10 version CPU overclocking patch
#cp $(dirname $0)/../extra-files/322-mt7621-fix-cpu-clk-add-clkdev.patch target/linux/ramips/patches-5.10/

# set up WiFi
#sed -i 's/OpenWrt/coolxiaomi/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh
#sed -i 's/wireless.default_radio${devidx}.encryption=none/wireless.default_radio${devidx}.encryption=psk-mixed/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh
#sed -i '/encryption/a\set wireless.default_radio${devidx}.key=coolxiaomi' package/kernel/mac80211/files/lib/wifi/mac80211.sh
#sed -i '/encryption/a\set wireless.default_radio${devidx}.key=coolphicomm' package/kernel/mac80211/files/lib/wifi/mac80211.sh

# modify login password to coolxiaomi
#sed -i '/root/croot:$1$CBd7u73H$LvSDVXLBrzpk4JfuuN.Lv1:18676:0:99999:7:::' package/base-files/files/etc/shadow

# replace geodata source
. $(dirname $0)/../extra-files/update-geodata.sh

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
sed -i  's/^.*Port.*/Port 22\n#/'   package/network/services/dropbear/files/dropbear.config
uci set dropbear.@dropbear[0].Enable='0' 

# Enable OpenVPN service
/etc/init.d/openvpn enable
