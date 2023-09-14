#!/usr/bin/env bash

set -e -u

# Usage.
usage() {
  echo "Usage: ./local/install.sh [OPTIONS]" >&2
  echo "-h                    : Display usage" >&2
  echo "-m                    : Create local image" >&2
  echo "-i                    : Install site" >&2
  echo "-c                    : Use existing config to install site" >&2
  echo "-d                    : Install dev dependencies" >&2
  echo "-x                    : Shutdown and remove the site containers" >&2
  echo "-v                    : Also remove the volumes when shutting down the containers" >&2
  exit 1
}

create_image="no"
install_site="no"
use_existing_config="no"
install_dev_dependencies="no"
shutdown="no"
shutdown_options=""

# Parse options.
while getopts "hmicdxv" opt; do
  case $opt in
    h)
      usage
      ;;
    m)
      create_image="yes"
      ;;
    i)
      install_site="yes"
      ;;
    c)
      use_existing_config="yes"
      ;;
    d)
      install_dev_dependencies="yes"
      ;;
    x)
      shutdown="yes"
      ;;
    v)
      shutdown_options="$shutdown_options -v"
      ;;
    *)
      usage
      ;;
  esac
done

function docker_compose {
  docker compose -f local/docker-compose.yml "$@"
}

# Load the environment variables.
# They are only available in this script as we don't export them.
source local/.env

# Stop and remove the containers.
if [ "$shutdown" = "yes" ]; then
  echo "Stop and remove the containers."
  docker_compose down $shutdown_options || true
  exit 0
fi


# Build local image.
if [ "$create_image" = "yes" ]; then
  echo "Build local image."
  make IMAGE_NAME=$IMAGE_NAME IMAGE_TAG=$IMAGE_TAG
fi;

# Create the site and mysql containers.
echo "Create the site and mysql containers."
docker_compose up -d --remove-orphans

# Wait a bit for  mysql to be ready.
echo "Wait a bit for mysql to be ready."
sleep 10

# Dump some information about the created containers.
echo "Dump some information about the created containers."
docker_compose ps -a

# Install the site.
if [ "$install_site" = "yes" ]; then
  # Ensure the file directories are writable.
  echo "Ensure the file directories are writable."
  docker_compose exec site chmod -R 777 /srv/www/html/sites/default/files /srv/www/html/sites/default/private

  # Copy the existing settings.php and ensure the settings.php file is writable.
  echo "Ensure the settings.php writable."
  docker_compose exec site sh -c "cp /srv/www/html/sites/default/settings.php /srv/www/html/sites/default/settings.php.backup"
  docker_compose exec site chmod 666 /srv/www/html/sites/default/settings.php

  # Install the subtheme.
  echo "Install the common design subtheme if not present already."
  docker_compose exec -w /srv/www site composer run sub-theme || true

  # Install the site with the existing config.
  if [ "$use_existing_config" = "yes" ]; then
    echo "Install the site with the existing config."
    docker_compose exec -u appuser site drush -y si --existing-config minimal install_configure_form.enable_update_status_emails=NULL
  else
    echo "Install the site from scratch."
    docker_compose exec -u appuser site drush -y si minimal install_configure_form.enable_update_status_emails=NULL
  fi

  # Import the configuration.
  docker_compose exec -u appuser site drush -y cim

  # Restore the our copy of the settings.php.
  echo "Restore the settings.php."
  docker_compose exec site sh -c "mv /srv/www/html/sites/default/settings.php.backup /srv/www/html/sites/default/settings.php"
fi

# Install the dev dependencies and re-import the configuration.
if [ "$install_dev_dependencies" = "yes" ]; then
  # Install the dev dependencies.
  echo "Install the dev dependencies."
  docker_compose exec -w /srv/www site composer install

  # Import the configuration.
  docker_compose exec -u appuser site drush -y cr

  # Import the configuration.
  docker_compose exec  -u appuser site drush -y updatedb --no-post-updates

  # Import the configuration.
  docker_compose exec  -u appuser site drush -y cim

  # Import the configuration.
  docker_compose exec  -u appuser site drush -y updatedb

  # Enable the devel module.
  docker_compose exec  -u appuser site drush -y en devel

  # Enable the stage file proxy module.
  docker_compose exec  -u appuser site drush -y en stage_file_proxy
fi
