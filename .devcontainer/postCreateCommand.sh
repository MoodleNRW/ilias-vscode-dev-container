#!/usr/bin/env bash

until mysql -h db -u mariadb -pmariadb mariadb -e 'exit'; do
  sleep 1
done

PWD="$(pwd)"

# ILIAS
echo -e "\nInstall ILIAS\n"
sudo chmod 755 $PWD &&
sudo rm -rf /var/www/html && 
sudo ln -s $PWD /var/www/html &&

for ILIAS_VERSION in $ILIAS_VERSION; do
DATADIR=/var/www/iliasdata-${ILIAS_VERSION}
if [ -d "$DATADIR" ]; then
  sudo rm -rf $DATADIR
fi

if [ ! -d "$DATADIR" ]; then
  sudo mkdir -p $DATADIR &&
  sudo chown www-data:www-data $DATADIR &&
  sudo chmod 700 $DATADIR
fi

ILIASDIR=$PWD/ilias-${ILIAS_VERSION}
if [ ! -d "$ILIASDIR" ]; then
  git clone -b release_${ILIAS_VERSION} https://github.com/ILIAS-eLearning/ILIAS.git $ILIASDIR --depth 1
fi

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
done