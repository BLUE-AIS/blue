#!/bin/bash

# **Script: install_terraform.sh**
# Description: Installation de Terraform sur un serveur Proxmox fonctionnant sur un serveur physique Cisco.

# Variables
TERRAFORM_VERSION="1.6.0" # Remplacez par la version souhaitée
DOWNLOAD_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
INSTALL_DIR="/usr/local/bin"

# Lien miroirs pour les ISO
WINDOWS_SERVER_2019_ISO="https://image.cloud.example.com/windows_server_2019.iso"
DEBIAN_12_ISO="https://image.cloud.example.com/debian_12.iso"
PROXMOX_ISO="https://image.cloud.example.com/proxmox.iso"
OPNSENSE_ISO="https://image.cloud.example.com/opnsense.iso"

# Mise à jour du système
echo "Mise à jour des paquets du système..."
apt update && apt upgrade -y

# Installation des dépendances requises
echo "Installation des paquets nécessaires..."
apt install -y wget unzip curl

# Téléchargement de Terraform
echo "Téléchargement de Terraform version $TERRAFORM_VERSION..."
cd /tmp
wget $DOWNLOAD_URL -O terraform.zip
if [ $? -ne 0 ]; then
    echo "Erreur lors du téléchargement de Terraform. Vérifiez l'URL ou la connectivité réseau."
    exit 1
fi

# Extraction et installation
echo "Extraction de Terraform..."
unzip terraform.zip
mv terraform $INSTALL_DIR/

# Vérification de l'installation
echo "Vérification de l'installation de Terraform..."
terraform -version
if [ $? -ne 0 ]; then
    echo "Erreur lors de l'installation de Terraform."
    exit 1
fi

# Téléchargement des ISO
echo "Téléchargement des ISO nécessaires..."
wget $WINDOWS_SERVER_2019_ISO -O /var/lib/vz/template/iso/windows_server_2019.iso
wget $DEBIAN_12_ISO -O /var/lib/vz/template/iso/debian_12.iso
wget $PROXMOX_ISO -O /var/lib/vz/template/iso/proxmox.iso
wget $OPNSENSE_ISO -O /var/lib/vz/template/iso/opnsense.iso

# Configuration de Terraform pour Proxmox
PROVIDER_URL="https://github.com/Telmate/terraform-provider-proxmox"
PROVIDER_INSTALL_DIR="~/.terraform.d/plugins/"

# Téléchargement du provider Terraform pour Proxmox
echo "Installation du provider Terraform pour Proxmox..."
git clone $PROVIDER_URL /tmp/terraform-provider-proxmox
cd /tmp/terraform-provider-proxmox
make
mkdir -p $PROVIDER_INSTALL_DIR
mv terraform-provider-proxmox $PROVIDER_INSTALL_DIR

# Finalisation
echo "Terraform, les ISO et le provider Proxmox ont été installés avec succès !"

# Conseils
cat <<EOF

Configuration requise :
1. Configurez un fichier Terraform (.tf) pour déployer vos ressources sur Proxmox.
2. Exemple d'utilisation :

provider "proxmox" {
  pm_api_url = "https://10.1.0.20:8006/api2/json"
  pm_user    = "root@pam"
  pm_password = var.proxmox_password
}

resource "proxmox_vm_qemu" "example" {
  name       = "example-vm"
  target_node = "node1"
  clone      = "template-name"
  cores      = 2
  memory     = 2048
  disk {
    size = "10G"
  }
  network {
    model = "virtio"
    bridge = "vmbr0"
  }
}

EOF
