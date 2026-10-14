#!/bin/bash

echo "Start AdGuardHome Core Download !"
echo "Current Path: $PWD"

# GitHub API auth: pakai GITHUB_TOKEN dari workflow (limit 1000 req/jam).
# Tanpa token, request anonim dibatasi 60 req/jam per IP runner -> URL kosong
# ("http://: Invalid host name") dan firmware jadi TANPA core AdGuardHome.
GH_AUTH=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
    GH_AUTH=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

agh_api="https://api.github.com/repos/AdguardTeam/AdGuardHome/releases" 
agh_file="AdGuardHome_linux_$ARCH_1"
agh_file_down="$(curl -s "${GH_AUTH[@]}" ${agh_api}/latest | grep "browser_download_url" | grep -oE "https.*${agh_file}.*.tar.gz" | head -n 1)"
latest_version=$(curl -sSL "${GH_AUTH[@]}" "$agh_api/latest" | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n 1)

if [ -z "$agh_file_down" ]; then
  echo "Error: Gagal mengambil URL AdGuardHome dari GitHub API (rate-limit / API berubah)."
  echo "Build dihentikan agar firmware tidak jadi tanpa core AdGuardHome."
  exit 1
fi

if wget -nv "$agh_file_down" -P files/opt; then
  echo "Extracting core"
  if tar -zxvf files/opt/AdGuardHome_linux_"$ARCH_1".tar.gz -C files/opt; then
    rm files/opt/AdGuardHome_linux_"$ARCH_1".tar.gz
    echo "Done! Installed AdGuardHome version $latest_version"
  else
    echo "Error: Failed to extract AdGuardHome."
  fi
else
  echo "Error: Failed to download AdGuardHome."
fi
