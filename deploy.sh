#!/bin/bash

echo -e '\033[42m[Run->]\033[0m Get config data'
DB_USER=$(aws ssm get-parameters --name DB_USER --region eu-central-1 --output text --query Parameters[].Value)
DB_NAME_WP=$(aws ssm get-parameters --name DB_NAME_WP --region eu-central-1 --output text --query Parameters[].Value)
DB_HOST=$(aws ssm get-parameters --name DB_HOST --region eu-central-1 --output text --query Parameters[].Value)
DB_PASSWORD=$(aws ssm get-parameters --name DB_PASSWORD --region eu-central-1 --with-decryption --output text --query Parameters[].Value)
AWS_ACCESS_KEY_ID=$(aws ssm get-parameters --name _AWS_ACCESS_KEY_ID --region eu-central-1 --output text --query Parameters[].Value)
AWS_SECRET_ACCESS_KEY=$(aws ssm get-parameters --name _AWS_SECRET_ACCESS_KEY --region eu-central-1 --with-decryption --output text --query Parameters[].Value)

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
    --env WORDPRESS_AUTH_KEY="]~OondjIK5CXv[G5T{623(inAxxY/;yMF)loj6HT9Az;ynbEz>8V-<<z28Q" \
    --env WORDPRESS_SECURE_AUTH_KEY="7D8q|]1rL3|[v_{Cop:=W=(8T]*D6s{+Nprb.d<XeSVqoj+LKa_h6Gx/;}Q_L{N#" \
    --env WORDPRESS_LOGGED_IN_KEY="[iCylNLAL@@p3VqVm:O:K^!V&FX}_LTwBf#mKd(/*dyc%s/5Gi:s,I+Q9b)5?tP" \
    --env WORDPRESS_NONCE_KEY="?:k5gl:}RsWvFl) ZEuY.J?LU_p (k#S$+!CYUoe[AE-CTAi!C<7feA} %1pZEJz" \
    --env WORDPRESS_AUTH_SALT="1zKKn={_!$-,X?dP%}Lmv:b4NXZm)6f6qIEx+SPSoF@K,IZb@FAJ/H@yVVU,Q" \
    --env WORDPRESS_SECURE_AUTH_SALT="R@IxC)x{@Sf+0J5}Z;8&TO09dZ>lejpmVCdd{4L~/N:$Ab<G[ChzOF/-}9z6]fa" \
    --env WORDPRESS_LOGGED_IN_SALT="L{u|D>K>OALM3(!zQ<@&@B&9P<}L;swJxE%ygdviffF.APZQhFzZ*IW@UIcEO sp" \
    --env WORDPRESS_NONCE_SALT="1)Wf0T]:EpgDdR-QnL<&K|18k+YEbsjaOvQ_r4fPk~U.vdTtKG6KQW>yXIS p@u" \
    --env AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    --env AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    --volume $WORKDIR/themes:/var/www/html/wp-content/themes \
    --name wordpress lonya/wordpress
	
docker run -d --network=editor -p 80:80 --restart=always --name nginx_editor nginx_editor

echo -e '\033[42m[Run->]\033[0m Configure wordpress'
docker run --rm -v --interactive --tty --volume $WORKDIR/themes/deus:/app composer:2 install
docker exec wordpress curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
docker exec wordpress chmod +x wp-cli.phar
docker exec wordpress mv wp-cli.phar /usr/local/bin/wp
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp theme delete twentynineteen --allow-root
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp theme delete twentytwenty --allow-root
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp theme delete twentytwentyone --allow-root
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp plugin install contact-form-7 --allow-root
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp plugin install flamingo --allow-root
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp plugin install remove-category-url --allow-root
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp plugin install tinymce-advanced --allow-root
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp plugin install wp-scss --allow-root
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp plugin install wp-mail-smtp --allow-root
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp plugin install amazon-s3-and-cloudfront --allow-root
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp plugin install wordpress-seo --allow-root
docker exec --env WORDPRESS_DB_HOST=$DB_HOST --env WORDPRESS_DB_USER=$DB_USER --env WORDPRESS_DB_PASSWORD=$DB_PASSWORD --env WORDPRESS_DB_NAME=$DB_NAME_WP wordpress wp plugin install simple-301-redirects --allow-root
docker exec wordpress chown www-data:www-data . -R
