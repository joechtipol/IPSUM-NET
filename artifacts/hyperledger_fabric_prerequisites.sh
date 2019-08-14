#!/bin/bash

AWS_REGION=$1
REPO_URL=$2
INSTANCE_USER=$3

#REPO_ACCOUNT_ID=$3

ORDERER_DOCKER_REPO=${REPO_URL}fabric-orderer:latest
PEER_DOCKER_REPO=${REPO_URL}fabric-peer:latest
TOOLS_DOCKER_REPO=${REPO_URL}fabric-tools:latest
EXPLORER_DOCKER_REPO=${REPO_URL}explorer:latest
EXPLORER_DB_DOCKER_REPO=${REPO_URL}explorer-db:latest
BASE_OS_DOCKER_REPO=${REPO_URL}fabric-baseos:latest
CCENV_DOCKER_REPO=${REPO_URL}fabric-ccenv:latest

echo "Preparing to install fabric pre-requisites from $AWS_REGION."
echo "Using Explorer Docker Repo: $EXPLORER_DOCKER_REPO"
echo "Using Explorer DB Docker Repo: $EXPLORER_DB_DOCKER_REPO"

chmod +x ./network-management-scripts/*
chmod +x ./tools-bin/*
chmod +x ./scripts/*
chmod +x *sh
chmod +x ../containers/blockchain-explorer-container/build-containers.sh
chmod +x ../containers/blockchain-explorer-container/blockchain-explorer/*sh

sudo yum -y install docker
sudo yum -y install epel-release
sudo yum -y install -y python-pip
sudo /usr/bin/pip install docker-compose
sudo /usr/bin/pip install --upgrade pip
sudo yum -y install go


#
# ensure docker started
#
sudo service docker start

#
# Get and install nodejs
#
curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -
sudo yum -y install -y gcc-c++ make
sudo yum -y install -y nodejs
sudo /usr/bin/npm install npm@5.6.0 -g

sudo -u $INSTANCE_USER ./nodejs_user_prerequisits.sh

usermod -a -G docker $INSTANCE_USER

echo "patched-1"

#
# Now grab the samples incase we'd like to experiement with other topologies
#

mkdir $HOME/devops/hyperledger-fabric-samples
mkdir $HOME/devops/hyperledger-fabric-samples/go
mkdir $HOME/devops/hyperledger-fabric-samples/platform-specific-binaries

echo "PATH=$PATH:$HOME/.local/bin:$HOME/bin" >>$HOME/.bash_profile
echo "export PATH=$PATH:/sbin:/bin:/usr/sbin:/usr/bin:/bin:/usr/local/bin:/home/$INSTANCE_USER/devops/HyperLedger-Ipsum-Network/artifacts/tools-bin" >> /home/$INSTANCE_USER/.bash_profile
echo "export FABRIC_CFG_PATH=/home/$INSTANCE_USER/devops/HyperLedger-Ipsum-Network/artifacts" >> /home/$INSTANCE_USER/.bash_profile

echo "alias gen='$HOME/devops/HyperLedger-Ipsum-Network/artifacts/prepare_fabric_artifacts_standalone.sh some.com organ1 organ2 organ3 mychannel $HOME/HyperLedger-Ipsum-Network/artifacts'" >> $HOME/.bash_profile
echo "alias down='$HOME/devops/HyperLedger-Ipsum-Network/artifacts/network-management-scripts/network.sh down'" >> $HOME/.bash_profile
echo "alias lsc='docker container list'" >> $HOME/.bash_profile
echo "alias up='$HOME/devops/HyperLedger-Ipsum-Network/artifacts/network-management-scripts/network.sh up'" >> $HOME/.bash_profile
echo "alias up-silent='$HOME/devops/HyperLedger-Ipsum-Network/artifacts/network-management-scripts/network.sh up-silent'" >> $HOME/.bash_profile
echo "alias transaction='$HOME/devops/HyperLedger-Ipsum-Network/artifacts/network-management-scripts/network.sh transaction'" >> $HOME/.bash_profile

cd $HOME/devops/hyperledger-fabric-samples

git clone -b master https://github.com/hyperledger/fabric-samples.git
cd fabric-samples
git checkout v1.1.0

#cd ../platform-specific-binaries
#curl -sSL https://goo.gl/6wtTN5 | bash -s 1.1.0

chown -R $INSTANCE_USER:$INSTANCE_USER $HOME/devops/hyperledger-fabric-samples
#eval `aws ecr get-login --no-include-email --region $AWS_REGION --registry-ids ${REPO_ACCOUNT_ID}`

#
# Get the Amazon Images
#
set -x
#eval `aws ecr get-login --no-include-email --region $AWS_REGION --registry-ids ${REPO_ACCOUNT_ID}`
docker pull $EXPLORER_DB_DOCKER_REPO
docker pull $EXPLORER_DOCKER_REPO
docker pull $ORDERER_DOCKER_REPO
docker pull $TOOLS_DOCKER_REPO
docker pull $PEER_DOCKER_REPO
docker pull $BASE_OS_DOCKER_REPO
docker pull $CCENV_DOCKER_REPO

#docker tag `docker image list | grep amazonaws | grep ccenv | awk '{print $3}'` hyperledger/fabric-ccenv:x86_64-1.1.0
#docker tag `docker image list | grep amazonaws | grep baseos | awk '{print $3}'` hyperledger/fabric-baseos:x86_64-0.4.6
set +x
