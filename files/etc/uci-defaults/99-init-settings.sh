#!/bin/sh

exec > /root/setup.log 2>&1

# dont remove!
echo "Installed Time: $(date '+%A, %d %B %Y %T')"
echo "###############################################"
echo "Processor: $(ubus call system board | grep '\"system\"' | sed 's/ \+/ /g' | awk -F'\"' '{print $4}')"
echo "Device Model: $(ubus call system board | grep '\"model\"' | sed 's/ \+/ /g' | awk -F'\"' '{print $4}')"
echo "Device Board: $(ubus call system board | grep '\"board_name\"' | sed 's/ \+/ /g' | awk -F'\"' '{print $4}')"
sed -i "s#_('Firmware Version'),(L.isObject(boardinfo.release)?boardinfo.release.description+' / ':'')+(luciversion||''),#_('Firmware Version'),(L.isObject(boardinfo.release)?boardinfo.release.description+' build by friWrt [Ouc3kNF6]':''),#g" /www/luci-static/resources/view/status/include/10_system.js
if grep -q "ImmortalWrt" /etc/openwrt_release; then
  sed -i "s/\(DISTRIB_DESCRIPTION='ImmortalWrt [0-9]*\.[0-9]*\.[0-9]*\).*'/\1'/g" /etc/openwrt_release
  echo Branch version: "$(grep 'DISTRIB_DESCRIPTION=' /etc/openwrt_release | awk -F"'" '{print $2}')"
elif grep -q "OpenWrt" /etc/openwrt_release; then
  sed -i "s/\(DISTRIB_DESCRIPTION='OpenWrt [0-9]*\.[0-9]*\.[0-9]*\).*'/\1'/g" /etc/openwrt_release
  echo Branch version: "$(grep 'DISTRIB_DESCRIPTION=' /etc/openwrt_release | awk -F"'" '{print $2}')"
fi
echo "Tunnel Installed: $(opkg list-installed | grep -e luci-app-openclash -e luci-app-neko -e luci-app-passwall | awk '{print $1}' | tr '\n' ' ')"
echo "###############################################"

# Set login root password
(echo "friwrt"; sleep 1; echo "friwrt") | passwd > /dev/null

# Set hostname and Timezone to Asia/Jakarta
echo "Setup NTP Server and Time Zone to Asia/Jakarta"
uci set system.@system[0].hostname='friWrt'
uci set system.@system[0].timezone='WIB-7'
uci set system.@system[0].zonename='Asia/Jakarta'
uci -q delete system.ntp.server
uci add_list system.ntp.server="pool.ntp.org"
uci add_list system.ntp.server="id.pool.ntp.org"
uci add_list system.ntp.server="time.google.com"
uci commit system

# configure wan interface
chmod +x /usr/lib/ModemManager/connection.d/10-report-down
echo "Setup WAN and LAN Interface"
uci set network.lan.ipaddr="192.168.3.2"
uci set network.lan.netmask="255.255.255.0"
uci set network.lan.gateway="192.168.3.1"
# Resolver box sendiri = AdGuardHome lokal (bukan 9.9.9.9), agar query
# health-check/tooling di box ikut difilter AGH.
uci -q delete network.lan.dns
uci add_list network.lan.dns="192.168.3.2"
uci set network.wan=interface 
uci set network.wan.proto='modemmanager'
uci set network.wan.device='/sys/devices/platform/scb/fd500000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0/usb2/2-1'
uci set network.wan.apn='internet'
uci set network.wan.auth='none'
uci set network.wan.iptype='ipv4'
uci set network.tethering=interface
uci set network.tethering.proto='dhcp'
uci set network.tethering.device='usb0'
uci commit network
uci set firewall.@zone[1].network='wan tethering'
uci commit firewall

# configure ipv6
uci -q delete dhcp.lan.dhcpv6
uci -q delete dhcp.lan.ra
uci -q delete dhcp.lan.ndp
uci commit dhcp

# configure WLAN
echo "Setup Wireless if available"
uci set wireless.@wifi-device[0].disabled='0'
uci set wireless.@wifi-iface[0].disabled='0'
uci set wireless.@wifi-iface[0].encryption='psk2'
uci set wireless.@wifi-iface[0].key='friwrt2024'
uci set wireless.@wifi-device[0].country='ID'
if grep -q "Raspberry Pi 4\|Raspberry Pi 3" /proc/cpuinfo; then
  uci set wireless.@wifi-iface[0].ssid='friWrt_5g'
  uci set wireless.@wifi-device[0].channel='149'
  uci set wireless.radio0.htmode='HT40'
  uci set wireless.radio0.band='5g'
else
  uci set wireless.@wifi-iface[0].ssid='friWrt_2g'
  uci set wireless.@wifi-device[0].channel='1'
  uci set wireless.@wifi-device[0].band='2g'
fi
uci commit wireless
wifi reload && wifi up
if iw dev | grep -q Interface; then
  if grep -q "Raspberry Pi 4\|Raspberry Pi 3" /proc/cpuinfo; then
    if ! grep -q "wifi up" /etc/rc.local; then
      sed -i '/exit 0/i # remove if you dont use wireless' /etc/rc.local
      sed -i '/exit 0/i sleep 10 && wifi up' /etc/rc.local
    fi
    if ! grep -q "wifi up" /etc/crontabs/root; then
      echo "# remove if you dont use wireless" >> /etc/crontabs/root
      echo "0 */12 * * * wifi down && sleep 5 && wifi up" >> /etc/crontabs/root
      service cron restart
    fi
  fi
else
  echo "No wireless device detected."
fi

# custom repo and Disable opkg signature check
echo "Setup custom repo using MyOPKG Repo"
if grep -qE '^VERSION_ID="21' /etc/os-release; then
  sed -i 's/option check_signature/# option check_signature/g' /etc/opkg.conf
  echo "src/gz custom_generic https://raw.githubusercontent.com/lrdrdn/my-opkg-repo/21.02/generic" >> /etc/opkg/customfeeds.conf
  echo "src/gz custom_arch https://raw.githubusercontent.com/lrdrdn/my-opkg-repo/21.02/$(grep "OPENWRT_ARCH" /etc/os-release | awk -F '"' '{print $2}')" >> /etc/opkg/customfeeds.conf
else
  sed -i 's/option check_signature/# option check_signature/g' /etc/opkg.conf
  echo "src/gz custom_generic https://raw.githubusercontent.com/lrdrdn/my-opkg-repo/main/generic" >> /etc/opkg/customfeeds.conf
  echo "src/gz custom_arch https://raw.githubusercontent.com/lrdrdn/my-opkg-repo/main/$(grep "OPENWRT_ARCH" /etc/os-release | awk -F '"' '{print $2}')" >> /etc/opkg/customfeeds.conf
fi

# r9: blok firewall SAMBA4 (NOTRACK 137-138/139/445) DIHAPUS — samba4-server sudah
# tidak dipasang pada build DNS-murni ini, jadi rule ini hanya menambah entri firewall
# yang tidak pernah dipakai.

# set argon as default theme
echo "Setup Default Theme"
uci set luci.main.mediaurlbase='/luci-static/argon' && uci commit

echo "Setup misc settings"
# remove login password required when accessing terminal
uci set ttyd.@ttyd[0].command='/bin/bash --login'
uci commit

# remove huawei me909s usb-modeswitch
sed -i -e '/12d1:15c1/,+5d' /etc/usb-mode.json

# remove dw5821e usb-modeswitch
sed -i -e '/413c:81d7/,+5d' /etc/usb-mode.json

# Disable /etc/config/xmm-modem
uci set xmm-modem.@xmm-modem[0].enable='0'
uci commit

# r9: setup nlbwmon & auto-backup vnstat DIHAPUS — paket nlbwmon dan
# vnstat2/vnstati2 sudah tidak dipasang (monitoring DB di overlay readonly).
# Blok ini dulu menghasilkan error `uci: Invalid argument` + service not found tiap boot.

# adjusting app catagory
sed -i 's/services/nas/g' /usr/lib/lua/luci/controller/aria2.lua 2>/dev/null || sed -i 's/services/nas/g' /usr/share/luci/menu.d/luci-app-aria2.json
sed -i 's/services/nas/g' /usr/share/luci/menu.d/luci-app-hd-idle.json
# r9: baris menu.d luci-app-samba4.json & luci-app-lite-watchdog.json DIHAPUS —
# kedua paket itu tidak dipasang pada build ini, jadi sed-nya gagal dan
# memunculkan "No such file or directory" di log first boot.

# setup misc settings
sed -i 's/\[ -f \/etc\/banner \] && cat \/etc\/banner/#&/' /etc/profile
sed -i 's/\[ -n "$FAILSAFE" \] && cat \/etc\/banner.failsafe/& || \/usr\/bin\/neofetch/' /etc/profile
# r9: baris `chmod +x /root/fix-tinyfm.sh && bash /root/fix-tinyfm.sh` DIHAPUS —
# luci-app-tinyfm + php8 sudah tidak dipasang, jadi file & kebutuhan patch-nya tidak ada.
chmod +x /root/install2.sh && bash /root/install2.sh
chmod +x /sbin/sync_time.sh
chmod +x /sbin/free.sh
chmod +x /usr/bin/neofetch
chmod +x /usr/bin/clock
chmod +x /usr/bin/mount_hdd
chmod +x /usr/bin/cek_sms.sh

# r9: blok "configurating openclash" dan "configurating neko" DIHAPUS TOTAL.
# Paket VPN client tidak pernah dipasang pada build ini, dan helper /usr/bin/openclash.sh
# + /usr/bin/patchoc.sh juga sudah dihapus dari repo — guard `if opkg list-installed`
# di sini jadi kode mati yang hanya menambah baris tanpa efek.

# adding new line for enable i2c oled display
if grep -q "Raspberry Pi 4\|Raspberry Pi 3" /proc/cpuinfo; then
  echo -e "\ndtparam=i2c1=on\ndtparam=spi=on\ndtparam=i2s=on" >> /boot/config.txt
fi

# enable adguardhome
chmod +x /usr/bin/adguardhome
#bash /usr/bin/adguardhome enable_agh

echo "All first boot setup complete!"

exit 0
