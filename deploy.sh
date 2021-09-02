#!/bin/bash

echo -e '\033[42m[Run->]\033[0m Get config data'
DB_USER=$(aws ssm get-parameters --name DB_USER --region eu-central-1 --output text --query Parameters[].Value)
DB_NAME_WP=$(aws ssm get-parameters --name DB_NAME_WP --region eu-central-1 --output text --query Parameters[].Value)
DB_HOST=$(aws ssm get-parameters --name DB_HOST --region eu-central-1 --output text --query Parameters[].Value)
DB_PASSWORD=$(aws ssm get-parameters --name DB_PASSWORD --region eu-central-1 --with-decryption --output text --query Parameters[].Value)

WORKDIR=/home/ec2-user
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
git clone git@github.com:DeusEditor/deus-wp-theme.git themes/deus

echo -e '\033[42m[Run->]\033[0m Building nginx image'
docker build -f $WORKDIR/docker-front/nginx/Dockerfile -t nginx_editor .

echo -e '\033[42m[Run->]\033[0m Run containers'
docker network create editor

docker run -d \
    --network=editor \
    -p 80 \
    --restart=always \
    --env WORDPRESS_DB_HOST=$DB_HOST \
    --env WORDPRESS_DB_USER=$DB_USER \
    --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD \
    --env WORDPRESS_DB_NAME=$DB_NAME_WP \
    --volume $WORKDIR/themes:/var/www/html/wp-content/themes \
    --name wordpress wordpress
	
docker run -d --network=editor -p 80:80 --restart=always --name nginx_editor nginx_editor

echo -e '\033[42m[Run->]\033[0m Configure wordpress'
docker exec wordpress curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
docker exec wordpress chmod +x wp-cli.phar
docker exec wordpress mv wp-cli.phar /usr/local/bin/wp
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp theme delete twentynineteen --allow-root
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp theme delete twentytwenty --allow-root
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp theme delete twentytwentyone --allow-root
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp plugin install contact-form-7 --allow-root
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp plugin install flamingo --allow-root
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp plugin install remove-category-url --allow-root
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp plugin install robots-txt-editor --allow-root
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp plugin install tinymce-advanced --allow-root
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp plugin install wp-scss --allow-root
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp plugin install wp-mail-smtp --allow-root
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp plugin install amazon-s3-and-cloudfront --allow-root
docker exec wordpress chown www-data:www-data . -R
