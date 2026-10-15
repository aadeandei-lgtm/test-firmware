#!/bin/bash

# Profile info
make info

# Main configuration name
PROFILE=""
PACKAGES=""

# (Optimized: modem/USB-LAN driver & tools DIHAPUS — target device full LAN via Ethernet)

# (r9: blok "Tunnel option" DIHAPUS TOTAL — OPENCLASH_FW3/FW4, NEKO, PASSWALL beserta
#  seluruh cabang pemilihan paketnya. Build ini khusus server DNS (AGH) murni, jadi
#  paket VPN client tidak pernah dipasang. Menghapusnya di sini = satu sumber kebenaran;
#  argumen $2 dari workflow sekarang diabaikan, tidak lagi menambah paket apa pun.
#  Semua paket VPN (openclash/passwall/neko/xray/sing-box/shadowsocks/dll) tidak akan
#  muncul lagi di image. Kalau nanti butuh VPN client, kembalikan blok ini dari git history.)

# Adguardhome
PACKAGES+=" luci-app-adguardhome ca-certificates ca-bundle tar unzip bind-tools"

# NAS and Hard disk tools
PACKAGES+=" luci-app-diskman luci-app-hd-idle luci-app-disks-info smartmontools kmod-usb-storage kmod-usb-storage-uas ntfs-3g"
PACKAGES+=" aria2 ariang luci-app-aria2"  # tinyfm DIHAPUS (butuh php8, tidak perlu); samba4-server+luci-app-samba4 DIHAPUS (fokus DNS server AGH murni)

# (Optimized: Docker DIHAPUS — tidak dibutuhkan untuk server AGH murni)

# Bandwidth And Network Monitoring
# (Stable fix: vnstat2/vnstati2/luci-app-vnstat2 DIHAPUS total — db readonly di overlay)
# (internet-detector-mod-modem-restart DIHAPUS — hanya untuk modem)
# (r12: luci-app-netmonitor DIHAPUS — menarik dependency netdata yang error + makan RAM)
# (r9: internet-detector + luci-app-internet-detector DIHAPUS — tidak dipakai pada server DNS
#  murni; paketnya dari feed eksternal fantastic-packages sehingga ikut menambah titik gagal build)
# nlbwmon+luci-app-nlbwmon DIHAPUS (fokus DNS server AGH murni)

# Speedtest
# (r9: librespeed-go + python3-speedtest-cli + iperf3 + luci-app-netspeedtest DIHAPUS.
#  Ini grup terbesar yang bisa dipangkas: python3-speedtest-cli menarik SELURUH suite
#  python3-* (9 paket, ~4,8 MB) hanya untuk tes kecepatan — tidak diperlukan server DNS.
#  Hemat ~9,4 MB + 13 paket.)

# Argon Theme
PACKAGES+=" luci-theme-argon luci-app-argon-config"

# (Base64/Alpha/RTA theme DIHAPUS: paket eksternal gagal diunduh saat build
#  sehingga opkg gagal install -> build berhenti di package_install)

# PHP8
# (Stable fix: php8 suite DIHAPUS — 78MB, hanya untuk tinyfm)
PACKAGES+=" libc coreutils-stat zoneinfo-asia"

# Misc and some custom .ipk files
misc=""
if [ "${RELEASE_BRANCH%:*}" == "openwrt" ]; then
    misc+=" luci-app-temp-status luci-app-cpu-status-mini"
elif [ "${RELEASE_BRANCH%:*}" == "immortalwrt" ]; then
    misc+=" "
fi

if [ "$(echo "$BRANCH" | cut -d'.' -f1)" == "21" ]; then
    misc+=" iptables-mod-ipopt"
else
    misc+=" "
fi

if [ "$1" == "rpi-4" ]; then
    misc+=" kmod-i2c-bcm2835 i2c-tools kmod-i2c-core kmod-i2c-gpio luci-app-oled"
elif [ "$ARCH_2" == "x86_64" ]; then
    misc+=" kmod-iwlwifi iw-full pciutils"
fi

if [ "$TYPE" == "AMLOGIC" ]; then
    # (Optimized: WiFi/ath9k/hostapd DIHAPUS — device full LAN via Ethernet)
    PACKAGES+=" luci-app-amlogic btrfs-progs kmod-crypto-acompress kmod-crypto-crc32c kmod-crypto-hash kmod-fs-btrfs"
fi

PACKAGES+=" $misc zram-swap adb parted losetup resize2fs luci luci-ssl block-mount luci-app-poweroff luci-app-log-viewer htop bash curl wget wget-ssl tar unzip unrar gzip jq luci-app-ttyd nano httping screen openssh-sftp-server"

# Optimasi khusus DNS server (entropy untuk DNSSEC + distribusi interrupt 8-core S912)
PACKAGES+=" haveged irqbalance"

# Exclude package (must use - before packages name)
# dnsmasq/dnsmasq-full dihapus: AGH langsung pegang port 53 (server AGH murni untuk MikroTik)
# modemmanager/netdata/vnstat/tinyfm/php8 dihapus: tidak dibutuhkan, makan RAM & rawan error
# r9 — modem PPP & IPv6: paket ini datang dari "Default Packages" ImageBuilder (bukan dari
#   PACKAGES+= kita), jadi HARUS di-exclude. Device ini full-LAN via Ethernet (tanpa modem)
#   dan IPv6 sudah dimatikan total di 95-noipv6-and-fixes.sh -> keduanya murni beban.
#   CATATAN: luci-proto-ppp & luci-proto-ipv6 TIDAK boleh di-exclude — keduanya dependensi
#   wajib luci-light (yang menarik luci & luci-ssl). Meng-exclude-nya = LuCI rusak total.
EXCLUDED=" -modemmanager -luci-proto-modemmanager -netdata -vnstat2 -vnstati2 -luci-app-vnstat2 -luci-app-tinyfm -php8 -php8-fpm -php8-fastcgi"
EXCLUDED+=" -ppp -ppp-mod-pppoe -odhcp6c -odhcpd-ipv6only"
if [ "${RELEASE_BRANCH%:*}" == "openwrt" ]; then
    EXCLUDED+=" -dnsmasq -dnsmasq-full"
elif [ "${RELEASE_BRANCH%:*}" == "immortalwrt" ]; then
    EXCLUDED+=" -dnsmasq -dnsmasq-full -automount -libustream-openssl -default-settings-chn -luci-i18n-base-zh-cn"
    if [ "$ARCH_2" == "x86_64" ]; then
      EXCLUDED+=" -kmod-usb-net-rtl8152-vendor"
    fi
fi

# Amlogic: procd-ujail di-exclude (butuh namespaces yang tidak ada di kernel vendor Amlogic).
# NB: dulu baris ini ada di blok TYPE=AMLOGIC di ATAS definisi EXCLUDED, sehingga
# nilai " -procd-ujail" langsung tertimpa oleh EXCLUDED="..." dan tidak pernah terpakai.
if [ "$TYPE" == "AMLOGIC" ]; then
    EXCLUDED+=" -procd-ujail"
fi

# Custom Files
FILES="files"

# Disable service
DISABLED_SERVICES="AdGuardHome"

# Start build firmware
make image PROFILE="$1" PACKAGES="$PACKAGES $EXCLUDED" FILES="$FILES" DISABLED_SERVICES="$DISABLED_SERVICES"
