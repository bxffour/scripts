#!/bin/bash

read -p "Name of regular user to set kubectl on: " USERNAME
HOME=/home/$USERNAME

# setting up cluster
kubeadm init --apiserver-advertise-address=$(ip -4 -o addr show eth0 | awk '{print $4}' | cut -d "/" -f 1) --pod-network-cidr=192.168.0.0/16

# setting up kubectl for regular user
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u $USERNAME):$(id -g $USERNAME) $HOME/.kube/config
