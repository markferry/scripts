#!/bin/sh

. ~/Repos/Scripts/bash/common/utilities.sh
. ~/Repos/Scripts/.secrets/secrets_pem.sh
. ~/Repos/Scripts/.secrets/server_host.sh
. ~/Repos/Scripts/.secrets/server_user.sh

echo
message green "EC2/JAVA" "Deploying 'ebay-service' to remote Tomcat.. \033[33m${EC2_SERVER_HOST}\033[0m"
echo

scp -i ${PEM_EU_WEST_1} -r ~/Repos/nimzo-java/ebay-service/target/ebay-service.war ${EC2_SERVER_USER}@${EC2_SERVER_HOST}:/tmp/

#ssh -t -l ${EC2_SERVER_USER} -i ${PEM_EU_WEST_1} ${EC2_SERVER_HOST} '
#cd $HOME/Repos/nimzo-ruby/scripts/server;
#./server-update-php.sh;
#'

echo
message green "EC2" "Deployment complete!"
echo