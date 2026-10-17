# Catatan Build — test-firmware (friWrt Amlogic)

Ditulis 16 Okt 2026 dari pengalaman build r1–r9. Baca ini SEBELUM mengubah `make-build.sh`
atau workflow supaya tidak mengulang kegagalan yang sama.

## Status terakhir
- Build terakhir: **run #9 sukses** (15 Okt, commit `9a8a120` "r9: hapus paket VPN client & pangkas build jadi minimal DNS AGH")
- Release aktif: `amlogic-s912-openwrt-23.05.3-october-2026-r9-MinimalDNS` (rootfs + 2 image: k5.15.222 & k6.1.189)
- Workflow utama: `generate-friwrt-amlogic.yml` (workflow_dispatch)
- Semua release r6–r9 sukses; r1–r5 penuh dengan kegagalan yang kini sudah jadi pelajaran di bawah.

## Riwayat kegagalan & penyebabnya (JANGAN diulang)
| Run | Penyebab | Pelajaran |
|-----|----------|-----------|
| #3 | Gagal di step "Packaging openwrt:23.05.3" (job openclash) | Step packaging openclash rapuh — kalau paket openclash berubah, cek step ini dulu |
| #4 | Gagal di step "Build Rootfs openwrt:23.05.3" | Rootfs gagal saat daftar paket ada yang bentrok/tak tersedia di feed — validasi nama paket sebelum push |
| #2, #5 | cancelled (manual) | Dibatalkan saat sedang iterate, bukan error build |
| #6+ | sukses semua | Setelah paket dipangkas & resolver diarahkan ke AGH lokal |

## Konfigurasi yang TERBUKTI jalan (paket & alur)
- **Target:** Amlogic T95Z-Plus (s912), branch `openwrt:23.05.3`, tunnel `no-tunnel`
- **Fokus build saat ini:** DNS server AdGuardHome murni
- **PACKAGES utama:** luci-app-adguardhome + ca-certificates/ca-bundle/tar/unzip/bind-tools;
  diskman/hd-idle/smartmontools/usb-storage/ntfs-3g; aria2+ariang; theme argon;
  zram-swap, adb, parted, htop, curl, wget, haveged, irqbalance; luci + luci-ssl
- **EXCLUDED (sengaja):**
  - `-modemmanager -luci-proto-modemmanager -netdata -vnstat2* -tinyfm -php8*` (perangkat ini full-LAN Ethernet, tanpa modem)
  - `-ppp -ppp-mod-pppoe -odhcp6c -odhcpd-ipv6only` (tanpa PPP/IPv6)
  - `-dnsmasq -dnsmasq-full` (digantikan AGH untuk mode standalone)
  - `-procd-ujail` untuk target amlogic
- **Ukuran `Installed-Size` pada manifest feed = BYTE, bukan KB** — penting saat estimasi rootfs.

## Jebakan AdGuardHome (sudah pernah memakan waktu)
- `luci-app-adguardhome` default: `redirect: 'exchange'` + `dns.port 1745` (didesain berdampingan dnsmasq).
  Untuk AGH **standalone**: set `redirect: none` di uci DAN `port: 53` di `AdGuardHome.yaml`.
  Kalau tidak, AGH TIDAK menerima query (dnsmasq tetap memegang port 53).
- Resolver box sendiri harus diarahkan ke **AdGuardHome lokal (192.168.3.2)**, bukan ke server pihak ketiga
  (perbaikan ini yang menyelesaikan run #8 — lihat commit `066c840`).

## Jebakan workflow & CI
- **Jangan hardcode path APK/artifact** — cari dinamis (`find ... -name '*.apk' | head -1`).
- Urutan `EXCLUDED` harus setelah definisi `EXCLUDED="..."`; kalau ditaruh sebelumnya, nilai append
  akan tertimpa (bug pernah terjadi dengan `-procd-ujail` — lihat komentar di `make-build.sh` baris 102).
- Feed 23.05.3 `aarch64_generic`: base/luci/packages/routing/telephony — daftar paket ada di `packages/`
  dan `external-package-urls.txt` (format: `(sign) <url>`, sign: all/arm64/x86/amlogic/all-all/...).
- Release dibuat manual setelah workflow sukses; asset = rootfs tar.gz + image .img.gz (k5.15 & k6.1).

## Checklist sebelum build berikutnya
1. [ ] Baca changelog & release terakhir (`r9-MinimalDNS`) — jangan menimpa tanpa tag baru.
2. [ ] Kalau menambah/menghapus paket: cek dulu ada di feed 23.05.3 atau di `external-package-urls.txt`.
3. [ ] Kalau ubah DNS/AGH: ingat jebakan `redirect: none` + `port: 53`.
4. [ ] Kalau ubah workflow: jangan hardcode path, jaga urutan EXCLUDED.
5. [ ] Jalankan workflow `generate-friwrt-amlogic.yml`, pantau step "Build Rootfs" & "Packaging" (2 titik gagal historis).
6. [ ] Setelah sukses: buat release dengan tag `amlogic-s912-openwrt-23.05.3-<bulan>-<tahun>-r<N>-<label>`.
7. [ ] Uji image di T95Z-Plus: cek LuCI (192.168.3.2), port 53 AGH aktif, query terjawab.

## Referensi
- Repo induk: `aadeandei-lgtm/friWrt-T95z-DNS` (fork frizkyiman/friWrt-MyWrtBuilder)
- ssh4 = T95Z-Plus yang dipakai untuk uji (OpenWrt 23.05.3, hostname friWrt, root/friwrt)
- Issue kernel yang LAZIM di firmware ini (bukan bug build): dwc2 USB HANG, panfrost regulator mali,
  brcmfmac fallback firmware generik — semua terjadi saat boot saja.
