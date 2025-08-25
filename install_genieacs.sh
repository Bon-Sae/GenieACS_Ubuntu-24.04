#!/bin/bash
# Script install GenieACS di Ubuntu 24.04 dengan warna + countdown

set -e

# Warna
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
NC="\033[0m" # No Color

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

echo -e "${CYAN}=== Install dependency dasar ===${NC}"
sudo apt install -y curl git build-essential redis-server

echo -e "${CYAN}=== Install MongoDB ===${NC}"
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl enable mongod
sudo systemctl start mongod

echo -e "${CYAN}=== Install Node.js (LTS) ===${NC}"
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

echo -e "${CYAN}=== Clone GenieACS ===${NC}"
cd /opt
sudo git clone https://github.com/genieacs/genieacs.git
cd genieacs
sudo npm install -g npm@11.5.2

echo -e "${CYAN}=== Buat service systemd ===${NC}"

# genieacs-cwmp
sudo tee /etc/systemd/system/genieacs-cwmp.service > /dev/null <<EOF
[Unit]
Description=GenieACS CWMP
After=network.target mongod.service redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/genieacs
ExecStart=/usr/bin/node dist/bin/genieacs-cwmp
Restart=always
User=root
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# genieacs-nbi
sudo tee /etc/systemd/system/genieacs-nbi.service > /dev/null <<EOF
[Unit]
Description=GenieACS NBI
After=network.target mongod.service redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/genieacs
ExecStart=/usr/bin/node dist/bin/genieacs-nbi
Restart=always
User=root
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# genieacs-fs
sudo tee /etc/systemd/system/genieacs-fs.service > /dev/null <<EOF
[Unit]
Description=GenieACS File Server
After=network.target mongod.service redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/genieacs
ExecStart=/usr/bin/node dist/bin/genieacs-fs
Restart=always
User=root
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# genieacs-ui
sudo tee /etc/systemd/system/genieacs-ui.service > /dev/null <<EOF
[Unit]
Description=GenieACS UI
After=network.target mongod.service redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/genieacs
ExecStart=/usr/bin/node dist/bin/genieacs-ui
Restart=always
User=root
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

echo -e "${CYAN}=== Reload systemd & enable service ===${NC}"
sudo systemctl daemon-reload
sudo systemctl enable genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui
sudo systemctl start genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui

echo
echo -e "${GREEN}=========================================="
echo -e "  Instalasi GenieACS selesai! 🎉"
echo -e "  Akses UI di: ${YELLOW}http://$(hostname -i):3000${NC}"
echo -e "==========================================${NC}"

