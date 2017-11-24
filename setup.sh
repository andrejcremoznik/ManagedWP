#!/bin/bash

if [ $# -lt 2 ]; then
  echo -e "\nUsage:"
  echo -e "  $0 <namespace> <project_path> [<branch>]"
  echo -e "\nParams:"
  echo -e "  <namespace>:    Lowercase alphanumeric name for your project. Must not start with a number. Must be directory / file system / URL friendly."
  echo -e "  <project_path>: Absolute path to directory where the project structure will be set up."
  echo -e "  <branch>:       Branch from which to create the project structure. Defaults to 'master'."
  echo -e "\nExample:"
  echo -e "  $0 mything /srv/http/mything.dev\n"
  exit
fi

namespace="$1"
project_path=${2%/}

# Make sure $project_path exists, is writeable and clean
if [ ! -d $project_path ]; then
  echo "==> The directory $project_path does not exist. Creating…"
  mkdir ${project_path}
  if [ $? -ne 0 ] ; then
    echo "==> Cannot create $project_path. Check write permissions. Aborting…"
  fi
else
  echo "==> The directory $project_path already exist."
  read -e -p "Delete everything inside $project_path? (y/n): " cont
  if [ "$cont" != "y" ]; then
    echo "Aborting…"
    exit
  fi
  if [ -w $project_path ] ; then
    cd $project_path
    rm -f .[^.] .??*
    rm -fr *
    cd - 2>&1 >/dev/null
  else
    echo "==> Cannot empty $project_path. Check write permissions. Aborting…"
  fi
fi

echo "==> Checking for required software…"
echo -e "For instructions on how to set these up, please read https://gist.github.com/andrejcremoznik/07429341fff4f318c5dd\n"

command -v composer >/dev/null 2>&1 || { echo >&2 "Composer not installed. Aborting…"; exit 1; }
command -v npm >/dev/null 2>&1 || { echo >&2 "NPM not installed. Aborting…"; exit 1; }
command -v wp >/dev/null 2>&1 || { echo >&2 "WP-CLI not installed. Aborting…"; exit 1; }

echo "==> All there."

# Export files to project
echo "==> Creating a working copy of ManagedWP in $project_path"
git archive --format=tar ${3:-master} | tar -x -C $project_path

echo -e "# ${namespace}\n" > ${project_path}/README.md
cp ${project_path}/.env.example ${project_path}/.env

echo -e "\nsync.sh export-ignore\nconfig/scripts/ export-ignore\nweb/app/uploads/ export-ignore\n" >> ${project_path}/.gitattributes

# Replace ManagedWP in file contents with $namespace
echo "==> Namespacing file contents…"
find ${project_path}/ -type f -print0 | xargs -0 sed -i "s/ManagedWP/${namespace}/g"

cd $project_path

echo -e "==> Installing composer dependencies…\n"
composer require composer/installers vlucas/phpdotenv johnpbloch/wordpress

echo -e "==> Installing NPM dependencies…\n"
npm install --save-dev node-ssh shelljs shx

echo -e "==> Symlinking default themes into web/app…\n"
ln -s ${project_path}/web/wp/wp-content/themes/* ${project_path}/web/app/themes/

echo -e "==> Done.\n"
echo "==> The following steps require a MySQL user with CREATE DATABASE privileges OR a user with basic use privileges for an existing database."

read -e -p "Do you wish to continue setting up WordPress? (y/n): " cont
if [ "$cont" != "y" ]; then
  echo "Edit $project_path/.env with your database settings and install WordPress using WP-CLI or your browser."
  exit
fi

read -e -p "Database name: " dbname
sed -i "s/db_name/${dbname}/g" .env

read -e -p "Database user: " dbuser
sed -i "s/db_user/${dbuser}/g" .env

read -e -p "Database password: " dbpass
sed -i "s/db_pass/${dbpass}/g" .env

read -e -p "Database host: " -i "localhost" dbhost
sed -i "s/localhost/${dbhost}/g" .env

read -e -p "Database table prefix: " -i "wpdb_" dbprefix
sed -i "s/wpdb_/${dbprefix}/g" .env
sed -i "s/wpdb_/${dbprefix}/g" sync.sh

read -e -p "Does user $dbuser have CREATE DATABASE privileges? Create database now? (y/n): " dbperms
if [ "$dbperms" == "y" ]; then
  wp db create
else
  read -p "Please create $dbname database manually and grant $dbuser all basic use privileges. Press [Enter] when done…"
fi

wp db reset --yes

read -e -p "Site title: " wp_title
read -e -p "Admin username: " -i "${namespace}admin" wp_user
read -e -p "Admin password: " wp_pass
read -e -p "Admin e-mail: " wp_email

echo "==> Installing WordPress…"
wp core install --url=http://${namespace}.dev --title="${wp_title}" --admin_user=${wp_user} --admin_password=${wp_pass} --admin_email=${wp_email}

echo "==> Removing demo content…"
wp site empty --yes
wp widget delete search-2 recent-posts-2 recent-comments-2 archives-2 categories-2 meta-2

echo "==> Creating developer admin account (login: dev / dev)"
wp user create dev dev@dev.dev --user_pass=dev --role=administrator

echo -e "==> All done.\n"
echo "Set up the web server and map the correct IP to $namespace.dev in your hosts file."
echo -e "Login at http://$namespace.dev/wp/wp-login.php (login: dev / dev)\n"
echo "Happy hacking!"
