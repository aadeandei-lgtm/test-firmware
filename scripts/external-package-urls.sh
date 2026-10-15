#!/bin/bash
# This script for custom download the latest packages version from snapshots/stable repo's url and github releases.
# Put file name and url base.
# GitHub API auth: pakai GITHUB_TOKEN dari workflow (limit 1000 req/jam).
# Tanpa token, request anonim dibatasi 60 req/jam per IP runner -> download
# paket diam-diam gagal (rate-limit) dan build error di opkg "Unknown package".
GH_AUTH=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
    GH_AUTH=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi


# Download packages from official snapshots, stable repo's urls and custom repo's.
{
files1=(
    #"luci-proto-modemmanager|https://downloads.openwrt.org/snapshots/packages/$ARCH_3/luci"
    #"luci-proto-mbim|https://downloads.openwrt.org/snapshots/packages/$ARCH_3/luci"
    #"modemmanager|https://downloads.openwrt.org/snapshots/packages/$ARCH_3/packages"
    #"libmbim|https://downloads.openwrt.org/snapshots/packages/$ARCH_3/packages"
    #"libqmi|https://downloads.openwrt.org/snapshots/packages/$ARCH_3/packages"
    "sms-tool|https://downloads.openwrt.org/snapshots/packages/$ARCH_3/packages"
    "luci-proto-modemmanager|https://downloads.openwrt.org/releases/packages-23.05/$ARCH_3/luci"
    "luci-proto-mbim|https://downloads.openwrt.org/releases/packages-23.05/$ARCH_3/luci"
    "modemmanager|https://downloads.openwrt.org/releases/packages-23.05/$ARCH_3/packages"
    "libmbim|https://downloads.openwrt.org/releases/packages-23.05/$ARCH_3/packages"
    "libqmi|https://downloads.openwrt.org/releases/packages-23.05/$ARCH_3/packages"
    #"sms-tool|https://downloads.openwrt.org/releases/packages-23.05/$ARCH_3/packages"
    "luci-app-argon-config|https://fantastic-packages.github.io/packages/releases/$(echo "$BRANCH" | cut -d'.' -f1-2)/packages/$ARCH_3/luci"
    "luci-theme-argon|https://fantastic-packages.github.io/packages/releases/$(echo "$BRANCH" | cut -d'.' -f1-2)/packages/$ARCH_3/luci"
    "luci-app-cpu-status-mini|https://fantastic-packages.github.io/packages/releases/$(echo "$BRANCH" | cut -d'.' -f1-2)/packages/$ARCH_3/luci"
    "luci-app-diskman|https://fantastic-packages.github.io/packages/releases/$(echo "$BRANCH" | cut -d'.' -f1-2)/packages/$ARCH_3/luci"
    "luci-app-disks-info|https://fantastic-packages.github.io/packages/releases/$(echo "$BRANCH" | cut -d'.' -f1-2)/packages/$ARCH_3/luci"
    "luci-app-log-viewer|https://fantastic-packages.github.io/packages/releases/23.05/packages/$ARCH_3/luci"
    "luci-app-temp-status|https://fantastic-packages.github.io/packages/releases/$(echo "$BRANCH" | cut -d'.' -f1-2)/packages/$ARCH_3/luci"
    # r9: entri internet-detector / luci-app-internet-detector / luci-app-netspeedtest /
    # python3-speedtest-cli / librespeed-go DIHAPUS dari sini juga — kalau paketnya sudah
    # tidak diminta PACKAGES tapi URL-nya masih diunduh, build tetap membawa paket itu
    # (atau gagal) karena kedua sisi harus konsisten.
    "luci-app-ramfree|https://downloads.staging.immortalwrt.org/snapshots/packages/$ARCH_3/luci"
)

echo "###########################################################"
echo "Downloading packages from official repo's and custom repo's"
echo "###########################################################"
echo "#"
for entry in "${files1[@]}"; do
    IFS="|" read -r filename1 base_url <<< "$entry"
    echo "Processing file: $filename1"
    file_urls=$(curl -sL "$base_url" | grep -oE "${filename1}_[0-9a-zA-Z\._~-]*\.ipk" | sort -V | tail -n 1)
    for file_url in $file_urls; do
        if [ ! -z "$file_url" ]; then
            echo "Downloading $file_url"
            echo "from $base_url/$file_url"
            curl -Lo "packages/$file_url" "$base_url/$file_url"
            echo "Packages [$filename1] downloaded successfully!."
            echo "#"
            break
        else
            echo "Failed to retrieve packages [$filename1] because it's different from $base_url/$file_url. Retrying before exit..."
        fi
    done
done
}

# Download custom packages from github release api urls
{
if [ "$TYPE" == "AMLOGIC" ]; then
    echo "Adding [luci-app-amlogic] from bulider script type."
    files2+=("luci-app-amlogic|https://api.github.com/repos/ophub/luci-app-amlogic/releases/latest")
fi

files2+=(
    "luci-app-adguardhome|https://api.github.com/repos/kongfl888/luci-app-adguardhome/releases/latest"
    "luci-app-sms-tool-js|https://api.github.com/repos/4IceG/luci-app-sms-tool-js/releases/latest"
    "luci-app-modemband|https://api.github.com/repos/4IceG/luci-app-modemband/releases/latest"
    "modemband|https://api.github.com/repos/4IceG/luci-app-modemband/releases/latest"
    "luci-app-lite-watchdog|https://api.github.com/repos/4IceG/luci-app-lite-watchdog/releases/latest"
    "luci-app-3ginfo-lite|https://api.github.com/repos/4IceG/luci-app-3ginfo-lite/releases/latest"
    "luci-app-netmonitor|https://api.github.com/repos/rtaserver/rta-packages/releases"
    "luci-app-base64|https://api.github.com/repos/rtaserver/rta-packages/releases"
    "luci-theme-rta|https://api.github.com/repos/rtaserver/RTA-Theme-OpenWrt/releases/latest"
    "luci-app-rtaconfig|https://api.github.com/repos/rtaserver/RTA-Theme-OpenWrt/releases/latest"
    "luci-theme-alpha|https://api.github.com/repos/derisamedia/luci-theme-alpha/releases/latest"
    "luci-app-alpha-config|https://api.github.com/repos/derisamedia/luci-theme-alpha/releases/latest"
)

echo "#########################################"
echo "Downloading packages from github releases"
echo "#########################################"
echo "#"
for entry in "${files2[@]}"; do
    IFS="|" read -r filename2 base_url <<< "$entry"
    echo "Processing file: $filename2"
    file_urls=$(curl -s "${GH_AUTH[@]}" "$base_url" | grep "browser_download_url" | grep -oE "https.*/${filename2}_[_0-9a-zA-Z\._~-]*\.ipk" | sort -V | tail -n 1)
    if [ -z "$file_urls" ]; then
        echo "WARNING: [$filename2] tidak ketemu di $base_url (kemungkinan rate-limit GitHub API atau nama aset berubah) - paket di-skip!"
    fi
    for file_url in $file_urls; do
        if [ ! -z "$file_url" ]; then
            echo "Downloading $(basename "$file_url")"
            echo "from $file_url"
            curl -Lo "packages/$(basename "$file_url")" "$file_url"
            echo "Packages [$filename2] downloaded successfully!."
            echo "#"
            break
        else
            echo "Failed to retrieve packages [$filename2] because it's different from $file_url. Retrying before exit..."
        fi
    done
done
}

#################################################################################################################################

# for testing download url before commiting
# remove comment# then copy to your terminal for testing it
# format for offical repo: "PACKAGE-NAME|https://downloads.openwrt.org/snapshots/packages/$ARCH_3/packages"
# format for github release: "PACKAGE-NAME|https://api.github.com/repos/GITHUBUSER/REPO-NAME/releases"

# official and custom repo
#{
#BRANCH="23.05.3"
#ARCH_3="x86_64"
#files1=(
#    "sms-tool|https://downloads.openwrt.org/snapshots/packages/$ARCH_3/packages"
#)
#for entry in "${files2[@]}"; do
#   IFS="|" read -r filename1 base_url <<< "$entry"
#   file_urls=$(curl -sL "$base_url" | grep -oE "${filename1}_[0-9a-zA-Z\._~-]*\.ipk" | sort -V | tail -n 1)
#   echo "file name: $filename1"
#   echo "remote file name: $file_urls"
#   echo "download url: $base_url/$file_urls"
#done
#}

# github release
#{
#BRANCH="23.05.3"
#ARCH_3="x86_64"
#files2=(
#    "luci-app-sms-tool-js|https://api.github.com/repos/4IceG/luci-app-sms-tool-js/releases"
#)
#for entry in "${files2[@]}"; do
#   IFS="|" read -r filename2 base_url <<< "$entry"
#   file_urls=$(curl -s "$base_url" | grep "browser_download_url" | grep -oE "https.*/${filename2}_[_0-9a-zA-Z\._~-]*\.ipk" | sort -V | tail -n 1)
#   echo "file name: $filename2"
#   echo "remote file name: $(basename "$file_urls")"
#   echo "download url: $file_urls"
#done
#}
