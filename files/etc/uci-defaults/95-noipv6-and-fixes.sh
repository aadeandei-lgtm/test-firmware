#!/bin/sh
# r12: Matikan IPv6 total + perbaikan sisa dari analisa log ssh4

# === 1. MATIKAN IPv6 TOTAL ===
# Nonaktifkan IPv6 di kernel
cat >> /etc/sysctl.d/10-noipv6.conf <<'EOF'
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

# Hapus ip6assign dari interface lan (jangan assign IPv6)
uci -q delete network.lan.ip6assign
uci -q delete network.globals.ula_prefix
uci commit network

# Matikan IPv6 DHCP client/relay — paketnya (odhcp6c, odhcpd-ipv6only) sudah
# di-exclude dari build, jadi file init-nya tidak ada. Guard -f supaya script
# tidak memunculkan error "not found" saat first boot.
[ -x /etc/init.d/odhcp6c ] && { /etc/init.d/odhcp6c disable 2>/dev/null; /etc/init.d/odhcp6c stop 2>/dev/null; }

# Set AGH: matikan juga DNS-over-IPv6 listener (biar bersih)
# (AGH bind_hosts 0.0.0.0 sudah IPv4 saja)

# === 2. FIX SISA (dari analisa log ssh4) ===
# Hapus netdata + luci-app-netmonitor (sumber error plugin + makan RAM)
opkg remove --force-depends netdata luci-app-netmonitor 2>/dev/null
[ -x /etc/init.d/netdata ] && { /etc/init.d/netdata stop 2>/dev/null; /etc/init.d/netdata disable 2>/dev/null; }

# Disable fixcpufreq.pl (error compile perl)
chmod -x /usr/sbin/fixcpufreq.pl 2>/dev/null

# r9: blok "Samba: bind ke br-lan" DIHAPUS — samba4 tidak dipasang pada build ini.
# (Kalau nanti samba dipakai lagi, kembalikan: uci set samba4.@samba[0].interface='br-lan')

exit 0
