#!/bin/bash

set -e  # Arrête le script en cas d'erreur

# Variables
BRIDGE="vmbr0"
STORAGE_POOL="local-lvm"
TEMPLATE_DIR="/var/lib/proxmox/images"
DISK_SIZE="10G"
MEMORY="2048"
CORES="2"
CLOUDINIT_DISK="local-lvm:cloudinit"

# Fonction de création de template
create_template() {
    local id=$1
    local name=$2
    local url=$3
    local img_file=$(basename "$url")

    echo "Création du template $name"
    mkdir -p "$TEMPLATE_DIR/$name"
    cd "$TEMPLATE_DIR/$name"
    wget "$url"

    qm create "$id" --name "$name" --net0 virtio,bridge="$BRIDGE" --scsihw virtio-scsi-single
    qm importdisk "$id" "$img_file" "$STORAGE_POOL"
    qm set "$id" --scsi0 "${STORAGE_POOL}:vm-${id}-disk-0"
    qm disk resize "$id" scsi0 "$DISK_SIZE"
    qm set "$id" --boot order=scsi0
    qm set "$id" --cpu host --cores "$CORES" --memory "$MEMORY"
    qm set "$id" --ide2 "$CLOUDINIT_DISK"
    qm set "$id" --agent enabled=1

    # Installation de Nginx dans le template Debian
    qm set "$id" --sshkey ~/.ssh/id_rsa.pub  # Ajouter une clé SSH pour l'accès
    qm set "$id" --ciuser root --cipassword 'password'  # Définir un mot de passe temporaire pour root
    qm start "$id"
    
    sleep 10  # Attendre que la VM démarre
    
    echo "Installation de Nginx sur le template Debian..."
    ssh root@$(qm guest cmd "$id" network-get-interfaces | jq -r '.[0].addresses[0].ip-address') <<EOF
        apt update && apt install -y nginx
        systemctl enable nginx
        systemctl start nginx
        echo "<h1>Template Debian avec Nginx</h1>" > /var/www/html/index.html
    EOF

    qm stop "$id"
    qm template "$id"
    cd ..
    echo "Fin de création du template $name"
}

# Création des pools 
pvesh create /pools --poolid zone-relais --comment "zone Relais"
pvesh create /pools --poolid zone-exposee --comment "zone exposée"
pvesh create /pools --poolid zone-interne --comment "zone service interne"
pvesh create /pools --poolid zone-testing --comment "zone parefeu"

# Templates 
create_template 9001 "debian.template"  "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
create_template 9002 "alma.template"    "https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-9.5-20241120.x86_64.qcow2"
create_template 9003 "windows.template" 
create_template 9004 "opnsense.template" 

pvesh set /pools/zone.templates --vm 9001
pvesh set /pools/zone.templates --vm 9002
pvesh set /pools/zone.templates --vm 9003
pvesh set /pools/zone.templates --vm 9004

echo "Fin de création du paramétrage de bases de proxmox"

# -------- Clonage des serveurs Web -------- #
NUM_SERVERS=3  # Nombre de serveurs web à créer
BASE_VM_ID=100  # ID de départ des VMs

for i in $(seq 1 $NUM_SERVERS); do
    NEW_VM_ID=$((BASE_VM_ID + i))
    NEW_VM_NAME="web-server-$i"

    echo "Clonage du serveur $NEW_VM_NAME avec ID $NEW_VM_ID..."
    qm clone 9001 "$NEW_VM_ID" --name "$NEW_VM_NAME" --full true --storage "$STORAGE_POOL"
    qm set "$NEW_VM_ID" --net0 virtio,bridge="$BRIDGE"
    qm start "$NEW_VM_ID"

    sleep 10  # Attendre le démarrage

    echo "Déploiement du fichier HTML personnalisé pour $NEW_VM_NAME..."
    ssh root@$(qm guest cmd "$NEW_VM_ID" network-get-interfaces | jq -r '.[0].addresses[0].ip-address') <<EOF
        echo "<h1>Bienvenue sur le serveur $NEW_VM_NAME</h1>" > /var/www/html/index.html
        systemctl restart nginx
    EOF

    echo "Serveur $NEW_VM_NAME déployé avec succès !"
done

echo "Tous les serveurs web sont opérationnels 🚀"
