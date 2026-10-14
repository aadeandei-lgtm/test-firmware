# What's New!

**Changelog** (14-10-2026) — server DNS AdGuardHome:
- resolver box sendiri: `list dns` di `files/etc/config/network` diubah dari `9.9.9.9` menjadi `192.168.3.2` (AdGuardHome lokal), dan di-assert ulang di `files/etc/uci-defaults/99-init-settings.sh` agar tidak kembali ke 9.9.9.9 saat first boot,
- `make-build.sh`: `EXCLUDED+=" -procd-ujail"` dipindah ke bawah definisi `EXCLUDED` — sebelumnya nilai `+=` tertimpa baris `EXCLUDED="..."` sehingga paket itu tetap masuk image (bukti: `Installing procd-ujail` 1 -> 0, total paket 322 -> 321),
- workflow: `steps.imagebuilder.outputs.status` diganti `steps.compile.outputs.status` (step `imagebuilder` tidak ada; yang benar `download`/`packages`/`scripts`/`compile`),
- workflow: `if [ "$CLEAN" == "true" ]; echo ...; then make clean; fi` diperbaiki menjadi `if [ "$CLEAN" == "true" ]; then echo ...; make clean; fi` — sintaks lama menjalankan `make clean` tanpa syarat,
- paket LuCI eksternal yang tidak tersedia di feed 23.05.3 dihapus (Base64, Alpha Theme/Config, RTA Theme/Config) agar build tidak mati di `package_install Error 255`,
- `GITHUB_TOKEN` diteruskan ke step unduh paket (cegah rate-limit anonim) + gagal keras bila URL inti AdGuardHome kosong.

**Changelog** (05-05-2024):
- add wifi on for HGP, unknown for BH (experimental) [PR#18](https://github.com/frizkyiman/friWrt-MyWrtBuilder/pull/18)
- add new tunnel option; neko-openclash,
- update several packages,
- add new script cek_sms.sh for modem rakitan,
- add and replace some packagas,
- replace some packages source,
- fix and tweak some script,
- update and fix bug on builder script,
- some adjustment and tweak on  builder script.

**Changelog** (30-03-2024):
- update openwrt to 23.05.3 latest branch,
- update immortalwrt to 23.05.2 latest branch,
- wifi on, maybe (?)
- add Neko and Passwall2 with new tunnel option,
- update core script back to download latest mihomo meta core,
- add Base62, Netmonitor packages,
- remove expand root fs to remaining space on 21.02 branch due packages "parted" can't do the job (still looking for alternate way),
- fix with update code and logic,
- a few adjustment and tweaks.

**Changelog** (11-03-2024):
- Initial release
- small fix and adjustment
