#!/bin/bash

WORKDIR=/home/ec2-user
HOST_API=`aws ssm get-parameters --name HOST_API --region eu-central-1 --output text --query Parameters[].Value`

cd $WORKDIR

echo -e '\033[42m[Run->]\033[0m yum update'
yum update -y

echo -e '\033[42m[Run->]\033[0m Installing git'
yum install git -y

echo -e '\033[42m[Run->]\033[0m Installing docker'
amazon-linux-extras install docker -y
service docker start

echo -e '\033[42m[Run->]\033[0m Clone'
ssh -o StrictHostKeyChecking=no git@github.com # allow git clone with accept rsa fingerprint
git clone git@github.com:DeusEditor/docker-front.git
git clone git@github.com:DeusEditor/editor.git
git clone git@github.com:DeusEditor/cabinet.git
git clone git@github.com:DeusEditor/site.git

echo -e '\033[42m[Run->]\033[0m Building editor'
docker run --rm -v --interactive --tty --volume $WORKDIR/editor:/app --workdir /app node:alpine yarn
docker run --rm -v --interactive --tty --volume $WORKDIR/editor:/app --workdir /app --env NODE_ENV=production --env HOST_API=$HOST_API node:alpine yarn build
rm -rf $WORKDIR/editor/node_modules

echo -e '\033[42m[Run->]\033[0m Building cabinet'
docker run --rm -v --interactive --tty --volume $WORKDIR/cabinet:/app --workdir /app node:alpine yarn
docker run --rm -v --interactive --tty --volume $WORKDIR/cabinet:/app --workdir /app --env NODE_ENV=production --env HOST_API=$HOST_API node:alpine yarn build
rm -rf $WORKDIR/cabinet/node_modules

echo -e '\033[42m[Run->]\033[0m Building nginx image'
docker build -f $WORKDIR/docker-front/nginx/Dockerfile -t nginx_editor .

echo -e '\033[42m[Run->]\033[0m Run containers'
docker network create editor
docker run -d --network=editor -p 80:80 --restart=always --name nginx_editor nginx_editor
