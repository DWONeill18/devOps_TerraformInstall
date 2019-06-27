#!/bin/bash

#update linux and download wget
sudo apt update
sudo apt install -y unzip wget

#download terraform
wget https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip

#unzip and move terraform executable 
unzip terraform_0.11.7_linux_amd64.zip
sudo mv terraform /usr/local/bin
rm terraform_0.11.7_linux_amd64.zip

#check terraform has been installed
terraform --version




