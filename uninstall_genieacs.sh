#!/bin/bash
set -e

RED="\033[0;31m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
NC="\033[0m"

echo -e "${CYAN}=========================================="
echo -e "   Full Uninstaller GenieACS + MongoDB + Node.js   "
echo -e "==========================================${NC}"

# Hentikan & disable semua service GenieACS
echo -e "${RED}>>> Menghentikan service GenieACS...${NC}"
systemctl stop genieacs-{cwmp,nbi,fs,ui} 2>/dev/null || true
systemctl disable genieacs-{cwmp,nbi,fs,ui} 2>/dev/null || true

# Hapus service unit
echo -e "${RED}>>> Menghapus service unit...${NC}"
rm -f /etc/systemd/system/genieacs-{cwmp,nbi,fs,ui}.service
systemctl daemon-reload
systemctl reset-failed

# Hapus file config & log
echo -e "${RED}>>> Menghapus file konfigurasi & log GenieACS...${NC}"
rm -rf /opt/genieacs
rm -rf /var/log/genieacs
rm -f /etc/logrotate.d/genieacs

# Hapus user genieacs
echo -e "${RED}>>> Menghapus user genieacs...${NC}"
if id "genieacs" &>/dev/null; then
    userdel -r genieacs || true
fi

# Hapus GenieACS npm
echo -e "${RED}>>> Menghapus paket npm GenieACS...${NC}"
npm uninstall -g genieacs || true

# Hapus MongoDB
echo -e "${RED}>>> Menghapus MongoDB...${NC}"
systemctl stop mongod 2>/dev/null || true
systemctl disable mongod 2>/dev/null || true
apt purge -y mongodb-org mongodb-org-* || true
rm -rf /var/log/mongodb /var/lib/mongodb
rm -f /etc/apt/sources.list.d/mongodb-org-7.0.list
rm -f /usr/share/keyrings/mongodb-server-7.0.gpg

# Hapus Node.js & npm
echo -e "${RED}>>> Menghapus Node.js & npm...${NC}"
apt purge -y nodejs npm || true
rm -rf /usr/lib/node_modules /usr/local/lib/node_modules
rm -f /etc/apt/sources.list.d/nodesource.list

# Hapus installer
echo -e "${RED}>>> Menghapus file installer lama...${NC}"
rm -f install.sh

# Bersihkan sisa-sisa
echo -e "${CYAN}>>> Membersihkan paket tidak terpakai...${NC}"
apt autoremove -y
apt clean

echo
echo -e "${GREEN}=========================================="
echo -e "   Semua paket & file terkait GenieACS sudah dihapus ✅"
echo -e "==========================================${NC}"
