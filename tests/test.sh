#!/usr/bin/env bash

# This is the equivalent of the tests in `.travis.yml` that can be run locally.

IMAGE_NAME=starterkit-test
IMAGE_TAG=test

function cleanup() {
  echo "Removing test containers"
  docker compose -f tests/docker-compose.yml down
  echo "Removing test images"
  docker rmi public.ecr.aws/unocha/$IMAGE_NAME:$IMAGE_TAG || true
}

trap cleanup ABRT EXIT HUP INT QUIT TERM

# Remove previous containers.
cleanup

# Build local image.
echo "Build local image."
make IMAGE_NAME=$IMAGE_NAME IMAGE_TAG=$IMAGE_TAG

# Create the site, memcache and mysql containers.
echo "Create the site, memcache and mysql containers."
IMAGE_NAME=$IMAGE_NAME IMAGE_TAG=$IMAGE_TAG docker compose -f tests/docker-compose.yml up -d

# Dump some information about the created containers.
echo "Dump some information about the created containers."
docker compose -f tests/docker-compose.yml ps -a

# Wait a bit for memcache and mysql to be ready.
echo "Wait a bit for memcache and mysql to be ready."
sleep 10

# Install the common design subtheme.
 echo "Make sure the common design subtheme is installed"
docker compose -f tests/docker-compose.yml exec -w /srv/www drupal composer run sub-theme

# Install the dev dependencies.
echo "docker compose -f tests/docker-compose.yml exec -w /srv/www drupal composer install"
docker compose -f tests/docker-compose.yml exec -w /srv/www drupal composer install

# Check coding standards.
echo "Check coding standards."
docker compose -f tests/docker-compose.yml exec -u appuser -w /srv/www drupal ./vendor/bin/phpcs -p --report=full ./html/modules/custom ./html/themes/custom

# Run unit tests.
echo "Run unit tests."
docker compose -f tests/docker-compose.yml exec -u root -w /srv/www drupal mkdir -p /srv/www/html/sites/default/files/browser_output
docker compose -f tests/docker-compose.yml exec -u root -w /srv/www -e BROWSERTEST_OUTPUT_DIRECTORY=/srv/www/html/sites/default/files/browser_output drupal php -d zend_extension=xdebug ./vendor/bin/phpunit --testsuite Unit --debug

# Install the site with the existing config.
echo "Install the site with the existing config."
docker compose -f tests/docker-compose.yml exec drupal drush -y si --existing-config
docker compose -f tests/docker-compose.yml exec drupal drush -y en dblog

# Ensure the file directories are writable.
echo "Ensure the file directories are writable."
docker compose -f tests/docker-compose.yml exec drupal chmod -R 777 /srv/www/html/sites/default/files /srv/www/html/sites/default/private

# Create the build logs directory and make sure it's writable.
echo "Create the build logs directory and make sure it's writable."
docker compose -f tests/docker-compose.yml exec -u root drupal mkdir -p /srv/www/html/build/logs
docker compose -f tests/docker-compose.yml exec -u root drupal chmod -R 777 /srv/www/html/build/logs

# Run all tests and generate coverage report.
echo "Run all tests and generate coverage report."
docker compose -f tests/docker-compose.yml exec -u root -w /srv/www -e XDEBUG_MODE=coverage -e BROWSERTEST_OUTPUT_DIRECTORY=/srv/www/html/sites/default/files/browser_output -e DTT_BASE_URL=http://127.0.0.1 drupal php -d zend_extension=xdebug ./vendor/bin/phpunit --coverage-clover /srv/www/html/build/logs/clover.xml --debug
