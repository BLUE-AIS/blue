# 01-Create-Template
 Creation de Template sur Proxmox

Ce repo a pour but de vous faire prendre en main à la fois terraform, mais aussi la notion de template cloud-init sur Terraform.
Assurez vous d'avoir les informations suivantes :
- L'adresse IP de votre serveur Proxmox
  
Assurez vous de disposer :
- d'une installation de terraform fonctionnelle.
- d'une connexion ssh sécurisé par clé sur l'adresse IP de votre Serveur Proxmox.
  
Depuis une machine sous Linux (WSL fonctionne aussi) :
- Cloner le repository :
  git clone https://github.com/BLUE-AIS/blue.git
- Editer le fichier 01.1_create_env_pve.sh et verifier l'existance des images clouds.
- Editer le fichier terraform.tfvars et ajouter vos informations.
     
initialiser votre terraform. 
visualiser le plan du deploiement.
appliquer le plan.
