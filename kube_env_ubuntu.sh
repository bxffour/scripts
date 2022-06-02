#!/bin/bash

read -p "Hostname: " HOSTNAME
read -p "Username: " USERNAME
read -p "Group: " GROUP

HOME=/home/$USERNAME/

# setting up OS variable for CRIO
VER=$(lsb_release -r | awk '{print $2}')
PFX=xUbuntu_

OS="$PFX$VER"
VERSION=1.24
K8S_VER="$VERSION.1-00"

# setting new hostname
echo "Setting Hostname"
hostname "$HOSTNAME"
echo "$HOSTNAME" > /etc/hostname

# turning off swap
echo "turning off swap"
swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# updating 
echo "updating..."
apt update -y

# Docker Function

Containerd() {

echo "Installing Docker"

apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y

apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Enabling CRI plugin for containerd
echo "enabling CRI plugin for containerd"

sed -i 's/^[^#]*["cri"]/#&/' /etc/containerd/config.toml

}

CRIO() {

echo "deb [signed-by=/usr/share/keyrings/libcontainers-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb [signed-by=/usr/share/keyrings/libcontainers-crio-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list

mkdir -p /usr/share/keyrings
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | gpg --dearmor -o /usr/share/keyrings/libcontainers-archive-keyring.gpg
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/Release.key | gpg --dearmor -o /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg

apt-get update
apt-get install -y cri-o cri-o-runc

}

if [[ $1 == "containerd" ]]
then
    Containerd
elif [[ $1 == "cri-o" ]]
then 
    CRIO
else
    echo "argument missing [containerd|cri-o]"
    exit 1
fi

# Installing kubeadm, kubectl & kubelet
echo "Installing kubeadm, kubectl and kubelet"

apt-get install -y apt-transport-https ca-certificates curl

curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

apt-get update

apt-get install -y kubelet=$K8S_VER kubectl=$K8S_VER kubeadm=$K8S_VER

# setting up new user
echo "Creating new user..." 

useradd --create-home --shell "/bin/bash" --groups "${GROUP}" "${USERNAME}"
usermod -aG docker "$USERNAME"

passwd --delete "${USERNAME}"
chage --lastday 0 "${USERNAME}"

# restarting the server
echo "restarting server"
reboot
