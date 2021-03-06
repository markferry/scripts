#!/bin/sh
# Sets up the 'nimzo-app' user on the EC2 MySQL instance (nimzo).

. ~/Repos/scripts/bash/common/utilities.sh
. ~/.secrets/secrets.sh

echo
message green "EC2" "Setting up user 'nimzo-app' on MySQL instance.. \033[33m${EC2_MYSQL_NIMZO_HOST}\033[0m"
echo

mysql -h ${EC2_MYSQL_NIMZO_HOST} -P 3306 -u ${EC2_MYSQL_NIMZO_ROOT_USER} -p${EC2_MYSQL_NIMZO_ROOT_PASS} -e " \
CREATE USER '${EC2_MYSQL_NIMZO_APP_USER}'@'%' IDENTIFIED BY '${EC2_MYSQL_NIMZO_APP_PASS}';
GRANT SELECT ON *.* TO '${EC2_MYSQL_NIMZO_APP_USER}'@'%';
GRANT INSERT ON *.* TO '${EC2_MYSQL_NIMZO_APP_USER}'@'%';
GRANT DELETE ON *.* TO '${EC2_MYSQL_NIMZO_APP_USER}'@'%';
GRANT UPDATE ON *.* TO '${EC2_MYSQL_NIMZO_APP_USER}'@'%';
FLUSH PRIVILEGES;
quit"