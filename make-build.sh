#!/bin/bash

# Profile info
make info

# Main configuration name
PROFILE=""
PACKAGES=""

# (Optimized: modem/USB-LAN driver & tools DIHAPUS — target device full LAN via Ethernet)

# Tunnel option
OPENCLASH_FW3="coreutils-nohup bash iptables dnsmasq-full curl ca-certificates ipset ip-full iptables-mod-tproxy iptables-mod-extra libcap libcap-bin ruby ruby-yaml kmod-tun unzip luci-compat luci luci-base luci-app-openclash"
OPENCLASH_FW4="coreutils-nohup bash dnsmasq-full curl ca-certificates ipset ip-full libcap libcap-bin ruby ruby-yaml kmod-tun kmod-inet-diag unzip kmod-nft-tproxy luci-compat luci luci-base luci-app-openclash"
NEKO="bash kmod-tun php8 php8-cgi luci-app-neko"
PASSWALL="ipset ipt2socks iptables iptables-legacy iptables-mod-iprange iptables-mod-socket iptables-mod-tproxy kmod-ipt-nat coreutils coreutils-base64 coreutils-nohup curl dns2socks ip-full libuci-lua lua luci-compat luci-lib-jsonc microsocks resolveip tcping unzip dns2tcp brook hysteria trojan-go xray-core xray-plugin sing-box chinadns-ng haproxy ip6tables-mod-nat kcptun-client naiveproxy pdnsd-alt shadowsocks-libev-ss-local shadowsocks-libev-ss-redir shadowsocks-libev-ss-server shadowsocks-rust-sslocal shadowsocksr-libev-ssr-local shadowsocksr-libev-ssr-redir shadowsocksr-libev-ssr-server simple-obfs trojan-plus v2ray-core v2ray-plugin luci-app-passwall luci-app-passwall2"
if [ "$2" == "openclash" ]; then
    PACKAGES+=" $([ "$(echo "$BRANCH" | cut -d'.' -f1)" == "21" ] && echo "$OPENCLASH_FW3" || echo "$OPENCLASH_FW4")"
elif [ "$2" == "neko" ]; then
    PACKAGES+=" $NEKO"
elif [ "$2" == "passwall" ]; then
    PACKAGES+=" $PASSWALL"
elif [ "$2" == "neko-openclash" ]; then
    PACKAGES+=" $([ "$(echo "$BRANCH" | cut -d'.' -f1)" == "21" ] && echo "$OPENCLASH_FW3" || echo "$OPENCLASH_FW4") $NEKO"
elif [ "$2" == "openclash-passwall" ]; then
    PACKAGES+=" $([ "$(echo "$BRANCH" | cut -d'.' -f1)" == "21" ] && echo "$OPENCLASH_FW3" || echo "$OPENCLASH_FW4") $PASSWALL"
elif [ "$2" == "neko-passwall" ]; then
    PACKAGES+=" $NEKO $PASSWALL"
elif [ "$2" == "openclash-passwall-neko" ]; then
    PACKAGES+=" $([ "$(echo "$BRANCH" | cut -d'.' -f1)" == "21" ] && echo "$OPENCLASH_FW3" || echo "$OPENCLASH_FW4") $NEKO $PASSWALL"
fi

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
PACKAGES+=" internet-detector luci-app-internet-detector"  # nlbwmon+luci-app-nlbwmon DIHAPUS (fokus DNS server AGH murni)

# Speedtest
PACKAGES+=" librespeed-go python3-speedtest-cli iperf3 luci-app-netspeedtest"

# Base64 Encode Decode
PACKAGES+=" luci-app-base64"

# Argon Theme
PACKAGES+=" luci-theme-argon luci-app-argon-config"

# Alpha Theme
PACKAGES+=" luci-theme-alpha luci-app-alpha-config"

# RTA Theme
PACKAGES+=" luci-theme-rta luci-app-rtaconfig"

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
    EXCLUDED+=" -procd-ujail"
fi

PACKAGES+=" $misc zram-swap adb parted losetup resize2fs luci luci-ssl block-mount luci-app-poweroff luci-app-log-viewer htop bash curl wget wget-ssl tar unzip unrar gzip jq luci-app-ttyd nano httping screen openssh-sftp-server"

# Optimasi khusus DNS server (entropy untuk DNSSEC + distribusi interrupt 8-core S912)
PACKAGES+=" haveged irqbalance"

# Exclude package (must use - before packages name)
# dnsmasq/dnsmasq-full dihapus: AGH langsung pegang port 53 (server AGH murni untuk MikroTik)
# modemmanager/netdata/vnstat/tinyfm/php8 dihapus: tidak dibutuhkan, makan RAM & rawan error
EXCLUDED=" -modemmanager -luci-proto-modemmanager -netdata -vnstat2 -vnstati2 -luci-app-vnstat2 -luci-app-tinyfm -php8 -php8-fpm -php8-fastcgi"
if [ "${RELEASE_BRANCH%:*}" == "openwrt" ]; then
    EXCLUDED+=" -dnsmasq -dnsmasq-full"
elif [ "${RELEASE_BRANCH%:*}" == "immortalwrt" ]; then
    EXCLUDED+=" -dnsmasq -dnsmasq-full -automount -libustream-openssl -default-settings-chn -luci-i18n-base-zh-cn"
    if [ "$ARCH_2" == "x86_64" ]; then
      EXCLUDED+=" -kmod-usb-net-rtl8152-vendor"
    fi
fi

# Custom Files
FILES="files"

# Disable service
DISABLED_SERVICES="AdGuardHome"

# Start build firmware
make image PROFILE="$1" PACKAGES="$PACKAGES $EXCLUDED" FILES="$FILES" DISABLED_SERVICES="$DISABLED_SERVICES"
