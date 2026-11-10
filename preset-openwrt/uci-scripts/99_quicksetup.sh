uci -q batch << EOF

# 1. تعيين اسم الجهاز (Hostname)
set system.@system[0].hostname='PROMAX'

# 2. تعطيل خدمات IPv6
set dhcp.lan.ra='disabled'
set dhcp.lan.dhcpv6='disabled'
set dhcp.lan.ndp='disabled'

# 3. تعطيل DHCP على LAN
set dhcp.lan.ignore='1'
set dhcp.lan.dynamicdhcp='0'

# 4. تعيين عنوان IP ثابت
set network.lan.proto='static'
set network.lan.ipaddr='192.168.1.21'
set network.lan.netmask='255.255.255.0'

# 5. تعيين الدولة (بنما) وتفعيل الواي فاي
set wireless.radio0.country='PA'
set wireless.radio0.disabled='0'
set wireless.default_radio0.disabled='0'
set wireless.default_radio0.ssid='PROMAX'
set wireless.default_radio0.encryption='none'
set wireless.default_radio0.isolate='1'
set wireless.default_radio0.disassoc_low_ack='0'

# 6. الراديو الثاني (إذا وجد)
set wireless.radio1.country='PA'
set wireless.radio1.disabled='0'
set wireless.default_radio1.disabled='0'
set wireless.default_radio1.ssid='PROMAX'
set wireless.default_radio1.encryption='none'
set wireless.default_radio1.isolate='1'
set wireless.default_radio1.disassoc_low_ack='0'

# 7. تعيين طاقة البث القصوى (40 dBm)
set wireless.radio0.txpower='40'
set wireless.radio1.txpower='36'

# 8. حذف واجهات WAN (لأنك تريد وضع Access Point فقط)
delete network.wan
delete network.wan6

commit system
commit dhcp
commit network
commit wireless

EOF
exit 0
