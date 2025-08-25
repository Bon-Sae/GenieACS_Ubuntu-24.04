#!/bin/bash
set -e

# Warna
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
NC="\033[0m"

echo -e "${CYAN}=========================================="
echo -e "   Installer GenieACS for Ubuntu 24.04   "
echo -e "==========================================${NC}"
echo
echo -e "${YELLOW}Instalasi akan dimulai dalam:${NC}"

for i in 3 2 1; do
    echo -e "${RED}$i${NC}..."
    sleep 1
done

echo -e "${GREEN}>>> Mulai instalasi GenieACS...${NC}"
sleep 1

echo -e "${CYAN}=== Update sistem ===${NC}"
sudo apt update && sudo apt upgrade -y

echo -e "${CYAN}=== Install MongoDB ===${NC}"
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl enable --now mongod

echo -e "${CYAN}=== Install Node.js (LTS) ===${NC}"
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

echo -e "${CYAN}=== Install GenieACS ===${NC}"
sudo npm install -g npm@latest
sudo npm install -g genieacs

# Buat user & direktori
sudo useradd -r -M -s /usr/sbin/nologin genieacs || true
sudo mkdir -p /opt/genieacs/ext
sudo mkdir -p /var/log/genieacs
sudo chown -R genieacs:genieacs /opt/genieacs /var/log/genieacs

echo -e "${CYAN}=== Buat file environment ===${NC}"
cat << EOF | sudo tee /opt/genieacs/genieacs.env
GENIEACS_CWMP_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-cwmp-access.log
GENIEACS_NBI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-nbi-access.log
GENIEACS_FS_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-fs-access.log
GENIEACS_UI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-ui-access.log
GENIEACS_DEBUG_FILE=/var/log/genieacs/genieacs-debug.yaml
GENIEACS_EXT_DIR=/opt/genieacs/ext
EOF

node -e "console.log('GENIEACS_UI_JWT_SECRET=' + require('crypto').randomBytes(64).toString('hex'))" | sudo tee -a /opt/genieacs/genieacs.env
sudo chown genieacs:genieacs /opt/genieacs/genieacs.env
sudo chmod 600 /opt/genieacs/genieacs.env

# Systemd services
for svc in cwmp nbi fs ui; do
cat << EOF | sudo tee /etc/systemd/system/genieacs-$svc.service
[Unit]
Description=GenieACS $svc
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-$svc
Restart=always

[Install]
WantedBy=multi-user.target
EOF
done

# logrotate
cat << EOF | sudo tee /etc/logrotate.d/genieacs
/var/log/genieacs/*.log /var/log/genieacs/*.yaml {
    daily
    rotate 30
    compress
    delaycompress
    dateext
    missingok
    notifempty
    copytruncate
}
EOF

echo -e "${CYAN}=== Reload systemd & enable services ===${NC}"
sudo systemctl daemon-reload
sudo systemctl enable --now genieacs-{cwmp,nbi,fs,ui}

cd GenieACS_Ubuntu-24.04
rm install.sh
mv uninstall_genieacs.sh /root/
rmdir GenieACS_Ubuntu-24.04
echo
echo -e "${GREEN}=========================================="
echo -e "  Instalasi GenieACS selesai! ??"
echo -e "  Akses UI di: ${YELLOW}http://$(hostname -I | awk '{print $1}'):3000${NC}"
echo -e "  Username : ${YELLOW}admin${NC}"
echo -e "  Password : ${YELLOW}admin${NC}"
echo -e "==========================================${NC}"
