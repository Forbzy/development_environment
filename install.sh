#!/bin/bash
set -eux

OS=$(cat /etc/os-release|sed -e 's/"//'|grep ID_LIKE|awk -F '=' '{print $2}'|awk '{print $1}')

if [ ${OS} == "debian" ]
then
  apt-get -y install python-pip git libssl-dev libffi-dev
  pip install 'docker-py==1.9.0'
fi

if [ ${OS} == "rhel" ]
then
  yum install -y epel-release 
  yum install -y git python-pip gcc-c++ openssl-devel python-devel
  pip install 'docker-py==1.9.0'
fi

pip install --upgrade pip setuptools ansible

apt install openjdk-8-jdk openssh-server -y

mkdir -p /opt/GIT
cd /opt/GIT

if [ ! -d development_environment ]
then
  git clone https://github.com/UKHomeOffice/development_environment.git development_environment
fi

cd development_environment
git fetch
git clean -fxd
git reset --hard

TAG=${TAG:-$(git tag | tail -n 1)}
echo "Running with Tag: ${TAG}"
git checkout ${TAG}

ansible-galaxy install -r requirements.yml

ansible-playbook -i hostfile -v site.yml

swapoff /dev/vg-workstation/swap
lvremove /dev/vg-workstation/swap
lvcreate -L 4G -n swap vg-workstation
dd if=/dev/zero of=/dev/vg-workstation/swap bs=1M count=4096
mkswap /dev/vg-workstation/swap
swapon /dev/vg-workstation/swap
lvextend -L +50G /dev/vg-workstation/home
lvextend -L +5G /dev/vg-workstation/var_log


exit
