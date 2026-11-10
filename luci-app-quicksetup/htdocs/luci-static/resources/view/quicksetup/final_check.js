'use strict';
'require view';
'require form';
'require uci';
'require fs';
'require ui';

return view.extend({
load: function() { return uci.load('wizard'); },
render: function() {
this.addStyles();
var params = new URLSearchParams(window.location.search);
var selectedMode = params.get('selectedMode');
if (!selectedMode) return this.renderCards();
return this.renderForm(selectedMode);
},
addStyles: function() {
if (document.getElementById('qs-styles')) return;
document.head.appendChild(E('style', { 'id': 'qs-styles' }, `
.mode-grid { display:flex; flex-wrap:wrap; gap:20px; margin:30px 0; justify-content:center; }
.mode-card { border-radius:8px; padding:4rem 1rem; text-align:center; flex:1; min-width:180px; max-width:200px; display:flex; flex-direction:column; align-items:center; color:#fff; text-decoration:none; box-shadow:0 .1rem .3rem rgba(0,0,0,.2); }
.mode-card[data-mode="pppoe_dial"]  { background:linear-gradient(135deg,#ff6b6b,#ff4757); }
.mode-card[data-mode="sender_mesh"] { background:linear-gradient(135deg,#da77f2,#be4bdb); }
.mode-card[data-mode="owifi_Vlan"]  { background:linear-gradient(135deg,#51cf66,#40c057); }
.mode-card[data-mode="sender_wds"]  { background:linear-gradient(135deg,#339af0,#228be6); }
.mode-icon-container { width:64px;height:64px;margin-bottom:15px;display:flex; align-items:center;justify-content:center; background:rgba(255,255,255,.2);border-radius:50%;padding:10px; }
.mode-icon { width:48px; height:48px; }
.mode-title { font-size:15px;font-weight:600;margin-top:10px; }
.mode-info-header { border-radius:8px; padding:1rem; margin:0 2% 2% 2%; display:flex; align-items:center; gap:15px; color:#fff; }
.mode-info-header[data-mode="pppoe_dial"]  { background:#ff6b6b; }
.mode-info-header[data-mode="sender_mesh"] { background:#da77f2; }
.mode-info-header[data-mode="owifi_Vlan"]  { background:#51cf66; }
.mode-info-header[data-mode="sender_wds"]  { background:#339af0; }
`));
},
getModeDetails: function(mode) {
var data = {
pppoe_dial:  { title: 'اتصال PPPoE', color: '#ff6b6b', icon: '<path fill="white" d="M19.35 10.04C18.67 6.59 15.64 4 12 4 9.11 4 6.6 5.64 5.35 8.04 2.34 8.36 0 10.91 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96z"/>', desc: 'للاتصال عبر ADSL أو الألياف.' },
owifi_Vlan:  { title: 'نقطة وصول (Access Point)', color: '#51cf66', icon: '<path fill="white" d="M12 3C7.79 3 4.14 5.34 2.29 8.5c-.37.66.11 1.5.9 1.5h17.63c.79 0 1.27-.84.9-1.5C19.86 5.34 16.21 3 12 3z"/>', desc: 'وضع نقطة الوصول مع دعم VLAN.' },
sender_wds:  { title: 'إعداد WDS', color: '#339af0', icon: '<path fill="white" d="M6.99 11L3 15l3.99 4v-3H14v-2H6.99v-3zM21 9l-3.99-4v3H10v2h7.01v3L21 9z"/>', desc: 'نظام التوزيع اللاسلكي.' },
sender_mesh: { title: 'شبكة MESH', color: '#da77f2', icon: '<path fill="white" d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2z"/>', desc: 'شبكات MESH للتجوال.' }
};
var d = data[mode] || data['owifi_Vlan'];
d.svg = '<img src="data:image/svg+xml;base64,' + btoa('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="40" height="40">' + d.icon + '</svg>') + '" class="mode-icon">';
return d;
},
renderCards: function() {
var self = this;
var container = E('div', {}, [ E('h3', { 'style': 'text-align:center;margin-top:4%' }, _('اختر وضع التشغيل')), E('p', { 'style': 'text-align:center' }, _('اختر وضع التشغيل اللاسلكي لجهازك:')) ]);
var grid = E('div', { 'class': 'mode-grid' });
['pppoe_dial', 'owifi_Vlan', 'sender_wds', 'sender_mesh'].forEach(function(id) {
var d = self.getModeDetails(id);
var iconDiv = E('div', { 'class': 'mode-icon-container' }); iconDiv.innerHTML = d.svg;
var card = E('a', { 'class': 'mode-card', 'href': '?selectedMode=' + id, 'data-mode': id }, [iconDiv, E('div', { 'class': 'mode-title' }, _(d.title))]);
grid.appendChild(card);
});
container.appendChild(grid);
return container;
},
renderForm: function(selectedMode) {
var d = this.getModeDetails(selectedMode);
var m = new form.Map('wizard', _('الإعداد السريع'), _('قم بتكوين إعدادات جهازك.'));
var s = m.section(form.NamedSection, 'default', 'wizard');
s.addremove = false; s.anonymous = true;

s.tab('modesetup', _('الوضع الحالي'));
s.tab('wansetup', _('إعدادات WAN'));
s.tab('wifisetup', _('الإعدادات اللاسلكية'));
s.tab('lansetup', _('إعدادات إضافية'));

var o = s.taboption('modesetup', form.DummyValue, '_current_mode', _('حالة الوضع الحالي'));
o.rawhtml = true;
o.default = '<div style="display:flex;align-items:center;flex-direction:column;"><div class="mode-icon-container" style="margin-bottom:20px;background:' + d.color + ';">' + d.svg + '</div><h3>' + _(d.title) + '</h3><p>' + _(d.desc) + '</p></div>';
o = s.taboption('modesetup', form.ListValue, 'MKSettings', _('وضع التشغيل'));
o.value('APMVL', _('MESH برمجة مش + فيلان'));
o.value('APVL', _('AP برمجة أكسس + فيلان'));
o.value('APWDSVL', _('WDS برمجة مرسل + فيلان'));
o.value('STWDSVL', _('WDS برمجة مستقبل + فيلان'));
o.value('AP', _('AP برمجة أكسس'));
o.value('APM', _('MESH برمجة مش'));
o.value('APWDS', _('WDS برمجة مرسل'));
o.value('STWDS', _('WDS برمجة مستقبل'));
o.value('APPPP', _('اكسس بوينت برودباند'));
if (selectedMode === 'owifi_Vlan') o.default = 'APVL';
else if (selectedMode === 'sender_mesh') o.default = 'APMVL';
else if (selectedMode === 'sender_wds') o.default = 'APWDSVL';
else if (selectedMode === 'pppoe_dial') o.default = 'APPPP';
else o.default = 'APVL';
o.readonly = true;

var infoWan = s.taboption('wansetup', form.DummyValue, '_info_wan', '');
infoWan.rawhtml = true;
infoWan.default = '<div class="mode-info-header" data-mode="' + selectedMode + '"><div style="width:64px;height:64px;">' + d.svg + '</div><div><h4>' + _(d.title) + '</h4><p>' + _(d.desc) + '</p></div></div>';
var infoWifi = s.taboption('wifisetup', form.DummyValue, '_info_wifi', '');
infoWifi.rawhtml = true;
infoWifi.default = infoWan.default;

o = s.taboption('wansetup', form.Value, 'PPPUSER', _('اسم مستخدم PPPoE')); o.depends('MKSettings', 'APPPP');
o = s.taboption('wansetup', form.Value, 'PPPPASS', _('كلمة مرور PPPoE')); o.depends('MKSettings', 'APPPP'); o.password = true;

o = s.taboption('wifisetup', form.Value, 'IPADD', _('عنوان IPv4'));
o.datatype = 'ip4addr';
o = s.taboption('wifisetup', form.Value, 'SSID2G', _('اسم الشبكة (SSID)'));
o.datatype = 'maxlength(32)';
o = s.taboption('wifisetup', form.ListValue, 'CH2G', _('قناة 2.4GHz')); o.value('auto', _('تلقائي')); for (var i=1;i<=11;i++) o.value(String(i));
o = s.taboption('wifisetup', form.ListValue, 'CH5G', _('قناة 5GHz')); o.value('auto', _('تلقائي')); [36,40,44,48,149,153,157,161,165].forEach(function(c){ o.value(String(c)); });

// حقل Mesh (يظهر دائماً، ولكن سيتم إخفاؤه برمجياً إذا لم نكن في وضع MESH)
o = s.taboption('wifisetup', form.Value, 'MESHID', _('عنوان Mesh'));
if (selectedMode !== 'sender_mesh') {
o.depends('MKSettings', 'APM'); // إخفاء الحقل إذا لم نكن في وضع MESH
}

o = s.taboption('wifisetup', form.ListValue, 'WKEYTYPE', _('التشفير')); o.value('none', _('بدون')); o.value('psk', _('WPA-PSK')); o.value('psk2', _('WPA2-PSK')); o.value('sae', _('WPA3-SAE'));
o = s.taboption('wifisetup', form.Value, 'WIFIKEY', _('كلمة المرور')); o.depends('WKEYTYPE', 'psk'); o.depends('WKEYTYPE', 'psk2'); o.depends('WKEYTYPE', 'sae'); o.password = true;

o = s.taboption('wifisetup', form.Flag, 'wifi_flag_Vlan', _('إضافة VLAN')); 
o.depends('MKSettings', 'APVL'); o.depends('MKSettings', 'APMVL'); o.depends('MKSettings', 'APWDSVL'); o.depends('MKSettings', 'STWDSVL');
o.default = '0';

o = s.taboption('wifisetup', form.Value, 'VLANID', _('رقم VLAN')); 
o.depends('wifi_flag_Vlan', '1');
o.datatype = 'range(1,4094)';

o = s.taboption('wifisetup', form.Flag, 'HIDDEN', _('إخفاء البث')); o.depends('MKSettings', 'APWDSVL'); o.depends('MKSettings', 'APWDS');

o = s.taboption('lansetup', form.Flag, 'STOPREST', _('إيقاف زر الفورمات')); o.default = '0';
o = s.taboption('lansetup', form.Flag, 'NO_NAT', _('إلغاء NAT')); o.default = '0';
o = s.taboption('lansetup', form.Flag, 'dhcpServer', _('إيقاف DHCP Server')); o.default = '0';
o = s.taboption('lansetup', form.Flag, 'NO_Firewall', _('إلغاء جدار الحماية')); o.default = '0';

var origSave = m.save;
m.save = L.bind(function(cb, silent) {
return origSave.call(this, cb, silent).then(function() {
return uci.save();
}).then(function() {
return fs.exec('/etc/init.d/wizard', ['start']);
}).then(function(res) {
if (res && res.code === 0) {
ui.addNotification(null, E('p', {}, '✅ تم التطبيق بنجاح! ستُعاد الشبكة خلال لحظات...'), 'info');
setTimeout(function() { window.location.reload(); }, 12000);
} else {
ui.addNotification(null, E('p', {}, '⚠️ خطأ: ' + (res ? res.code : '?')), 'error');
}
});
}, m);

return m.render();
}
});
