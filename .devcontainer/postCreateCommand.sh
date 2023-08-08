#!/usr/bin/env bash

until mysql -h db -u mariadb -pmariadb mariadb -e 'exit'; do
  sleep 1
done

PWD="$(pwd)"

# ILIAS
echo -e "\nInstall ILIAS\n"
sudo chmod 775 $PWD &&
sudo rm -rf /var/www/html && 
sudo ln -s $PWD /var/www/html

for ILIAS_VERSION in $ILIAS_VERSION; do
DATADIR=/opt/iliasdata-${ILIAS_VERSION}
if [ -d "$DATADIR" ]; then
  sudo rm -rf $DATADIR
fi

if [ ! -d "$DATADIR" ]; then
  ## Bei Umleitungsfehler diesen Schritt ggf noch einmal manuell ausführen.
echo -e "DATADIR doesnt exist"
  sudo mkdir -p $DATADIR 
fi

echo -e "DATADIR chmod"
sudo chown -R www-data:www-data $DATADIR &&
sudo chmod -R 775 $DATADIR

ILIASDIR=$PWD/ilias-${ILIAS_VERSION}
if [ ! -d "$ILIASDIR" ]; then
  git clone -b release_${ILIAS_VERSION} https://github.com/ILIAS-eLearning/ILIAS.git $ILIASDIR --depth 1
  if [ -d "$ILIASDIR/.git" ]; then
  sudo rm -rf $ILIASDIR/.git
  fi
  if [ -d "$ILIASDIR/.github" ]; then
  sudo rm -rf $ILIASDIR/.github
  fi
fi

MIN_CONFIG_JSON='{"common": {"client_id": "iliastest", "server_timezone": "Europe/Berlin"},"database": {"type": "innodb","host": "db","port": 3306,"database": "ilias_'$ILIAS_VERSION'","user": "ilias_'$ILIAS_VERSION'","password": "ilias"},"filesystem": {"data_dir": "'$DATADIR'"},"http": {"path": "'$ILIASDIR'" },"systemfolder": {"contact": {"firstname": "Admin","lastname": "Admin","email": "admin@idev.dev"}},"language": {"default_language": "de","install_languages": ["de", "en"],"install_local_languages": ["de"]},"logging": {"enable": true,"path_to_logfile": "/workspace/tmp/log/ilias_test.log","errorlog_dir": "/workspace/tmp/log/ilias_errorlogs/"},"utilities" : {"path_to_convert" : "/usr/bin/convert","path_to_zip" : "/usr/bin/zip","path_to_unzip" : "/usr/bin/unzip"}}'
sudo echo ${MIN_CONFIG_JSON} > .devcontainer/minimal-config.json
sudo cp .devcontainer/minimal-config.json /var/www/minimal-config.json

composer -d /var/www/html/ilias-${ILIAS_VERSION} update

ILIAS_VERSION_DB=${DB_NAME}_${ILIAS_VERSION}
ILIAS_VERSION_DB_USER=${DB_USER}_${ILIAS_VERSION}
# Drop data that might be existing from previous build
sudo mysql -h ${DB_HOST} -u root -p${DB_ROOT_PWD} -e "DROP DATABASE IF EXISTS ${ILIAS_VERSION_DB};"
sudo mysql -h ${DB_HOST} -u root -p${DB_ROOT_PWD} -e "DROP USER IF EXISTS ${ILIAS_VERSION_DB_USER}@'%';"
# Create database entitites for current version
sudo mysql -h ${DB_HOST} -u root -p${DB_ROOT_PWD} -e "CREATE DATABASE ${ILIAS_VERSION_DB} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
sudo mysql -h ${DB_HOST} -u root -p${DB_ROOT_PWD} -e "CREATE USER ${ILIAS_VERSION_DB_USER}@'%' IDENTIFIED BY '${DB_USER_PWD}';"
sudo mysql -h ${DB_HOST} -u root -p${DB_ROOT_PWD} -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,LOCK TABLES,ALTER ON ${ILIAS_VERSION_DB}.* TO ${ILIAS_VERSION_DB_USER}@'%';"
sudo mysql -h ${DB_HOST} -u root -p${DB_ROOT_PWD} -e "FLUSH PRIVILEGES;"

sudo php /var/www/html/ilias-${ILIAS_VERSION}/setup/setup.php install /var/www/minimal-config.json --yes

git config --global --add safe.directory $ILIASDIR

# Add cronjob for instance
(sudo crontab -l 2>/dev/null; echo "* * * * * /usr/local/bin/php /var/www/html/ilias-${ILIAS_VERSION}/cron/cron.php > /dev/null") | sudo crontab -
sudo chown -R www-data:www-data $ILIASDIR
done

sudo cp .devcontainer/php.ini /usr/local/etc/php/php.ini

if [ ! -d "$DATADIR/iliastest" ]; then
  sudo mkdir ${DATADIR}/iliastest
fi

sudo chown -R www-data:www-data ${DATADIR}/iliastest
sudo chmod -R 775 ${DATADIR}/iliastest

if [ ! -d "$PWD/tmp/log/ilias_errorlogs/" ]; then
  sudo mkdir -p $PWD/tmp/log/ilias_errorlogs/
fi

if [ ! -f "/var/www/ilias_test.log" ]; then
  sudo touch /workspace/tmp/log/ilias_test.log
fi

sudo chown -R www-data:www-data $PWD/tmp/
sudo chmod -R 775 $PWD/tmp/
