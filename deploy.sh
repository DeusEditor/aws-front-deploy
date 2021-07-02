#!/bin/bash

export HOST=`aws ssm get-parameters --name HOST --region eu-central-1 --output text --query Parameters[].Value`
export HOST_API=`aws ssm get-parameters --name HOST_API --region eu-central-1 --output text --query Parameters[].Value`

echo -e '\033[42m[Run->]\033[0m yum update'
sudo yum update -y

echo -e '\033[42m[Run->]\033[0m Installing git'
sudo yum install git -y

echo -e '\033[42m[Run->]\033[0m Installing docker'
sudo amazon-linux-extras install docker -y
sudo service docker start

echo -e '\033[42m[Run->]\033[0m Clone'
ssh -o StrictHostKeyChecking=no git@github.com # allow git clone with accept rsa fingerprint
git clone git@github.com:DeusEditor/docker-front.git
git clone git@github.com:DeusEditor/editor.git
git clone git@github.com:DeusEditor/cabinet.git
git clone git@github.com:DeusEditor/site.git

echo -e '\033[42m[Run->]\033[0m Building editor'
sudo docker run --rm -v --interactive --tty --volume $PWD/editor:/app --workdir /app node:alpine yarn
sudo docker run --rm -v --interactive --tty --volume $PWD/editor:/app --workdir /app --env NODE_ENV=production --env VUE_APP_API_URL=$HOST_API node:alpine yarn build
sudo rm -rf $PWD/editor/node_modules

echo -e '\033[42m[Run->]\033[0m Building cabinet'
sudo docker run --rm -v --interactive --tty --volume $PWD/cabinet:/app --workdir /app node:alpine yarn
sudo docker run --rm -v --interactive --tty --volume $PWD/cabinet:/app --workdir /app --env NODE_ENV=production --env VUE_APP_API_URL=$HOST_API node:alpine yarn build
sudo rm -rf $PWD/cabinet/node_modules

echo -e '\033[42m[Run->]\033[0m Building nginx image'
sudo docker build --build-arg HOST=$HOST -f docker-front/nginx/Dockerfile -t nginx_editor .

echo -e '\033[42m[Run->]\033[0m Run containers'
sudo docker network create editor
sudo docker run -d --network=editor -p 80:80 --restart=always --name nginx_editor nginx_editor
