#!/bin/sh

# SETTING TIMEZONE
uci set system.@system[0].timezone='WIB-8'
uci set system.@system[0].zonename='Asia/Makassar'
uci commit system

# SETTING TERMINAL
uci set ttyd.@ttyd[0].interface='@lan'
uci set ttyd.@ttyd[0].debug='7'
uci set ttyd.@ttyd[0].command='/usr/libexec/login.sh'
uci commit ttyd

# SETTING NETWORK
uci set network.wan=interface
uci set network.wan.proto='dhcp'
uci set network.wan.device='eth1'
uci commit network
uci set network.tethering=interface
uci set network.tethering.proto='dhcp'
uci set network.tethering.device='usb0'
uci commit network

# SETTING PHP
uci add_list uhttpd.main.interpreter='.php=/usr/bin/php-cgi'
uci add_list uhttpd.main.index_page='index.php'
uci commit uhttpd
sed -i 's/2M/512M/g' /etc/php.ini
sed -i 's/8M/512M/g' /etc/php.ini

# SETTING RELEASE RAM
cat <<'EOF' >/sbin/free.sh
sync && echo 3 > /proc/sys/vm/drop_caches && rm -rf /tmp/luci*
EOF
chmod 755 /sbin/free.sh

cat <<'EOF' >/usr/lib/lua/luci/controller/release_ram.lua
module("luci.controller.release_ram",package.seeall)
function index()
entry({"admin","status","release_ram"}, call("release_ram"), _("Release RAM"), 99)
end
function release_ram()
luci.sys.call("sync && echo 3 > /proc/sys/vm/drop_caches && rm -rf /tmp/luci*")
luci.http.redirect(luci.dispatcher.build_url("admin/status"))
end
EOF

cat <<'EOF' >/etc/crontabs/root
0 * * * * /sbin/free.sh >/dev/null 2>&1
EOF

# SETTING FILE MANAGER
cd /www/
unzip /www/tinyfm.zip

ln -s / /www/tinyfm/rootfs

cat <<'EOF' >/usr/lib/lua/luci/controller/tinyfm.lua
module("luci.controller.tinyfm", package.seeall)
function index()
entry({"admin","system","tinyfm"}, template("tinyfm"), _("File Manager"), 55).leaf=true
end
EOF

cat <<'EOF' >/usr/lib/lua/luci/view/tinyfm.htm
<%+header%>
<div class="cbi-map">
<br>
<iframe id="tinyfm" style="width: 100%; min-height: 650px; border: none; border-radius: 2px;"></iframe>
</div>
<script type="text/javascript">
document.getElementById("tinyfm").src = "http://" + window.location.hostname + "/tinyfm/tinyfm.php";
</script>
<%+footer%>
EOF

rm /www/tinyfm.zip

exit 0

