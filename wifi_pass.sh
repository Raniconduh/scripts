#!/usr/bin/zsh
read -s pass
printf '%s' "$pass" | iconv -t utf16le | openssl dgst -md4 -provider legacy | cut -d' ' -f2

# password=hash:...

# | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf
