# Local stack

The `local` folder contains scripts and docker/drupal configuration to create an instance of the site locally.

## Setup

1. Rename `local/.env.example` to `local/.env` and edit it to adjust the environement variables. The default should be enough.
2. Rename `local/shared/settings/settings.site.php.example` to `local/shared/settings/settings.site.php` and edit it to adjust the settings.

## Scripts

**Important:** Run the scripts from the root of the repository.

The script `./local/install.sh` is used to create/stop/remove containers etc. Run `./local/install.sh -h` to see the script options.

The script `./local/exec.sh` is a shortcut for `docker compose -f local/docker-compose.yml exec`

To run additional docker compose commands, use `docker compose -f local/docker-compose.yml` + `command`.

## Create instance

1. Run `./local/install.sh -m -c -i` to create an instance of the site (empty database) from the existing config.
2. Run `./local/exec.sh -T -u appuser site drush sqlc < path-to-db-dump.sql` to restore a database dump.
3. Run `./local/install.sh -d` to install the dev dependencies, import the config and update the database.

## Stop/start containers

- Run `./local/install.sh -s` to stop the containers
- Run `./local/install.sh` to start the containers

## Shutdown/recreate containers

- Run `./local/install.sh -x` to stop and remove the containers.
- Run `./local/install.sh -d` to recreate the containers and install the dev dependencies.

**Note:** Run `./local/install.sh -x -v` to completely clean up a local instance (remove containers and volumes). Follow the "create instance" above to recreate an instance.

## Update site image

After modifications to the composer files (for example, after the automatic composer update), it is recommended to recreate the local site image:

- Run `./local/install.sh -m -d` to recreate the site image and install the dev dependencies.

## Update service/base images

When a new image used by a service has been created by the OPS team (ex: new mysql or php image):

- Run `./local/insall.sh -u -d` to pull the service and base site images, recreate the local site image and the containers and install the dev dependencies.

When an image **with a new tag** has been created, then update the `local/docker-compose.yml` or the `docker/Dockerfile` accordingly before running the update command above.

## Composer

- Install all the modules (including dev) with `./local/exec.sh -w /srv/www site composer install`.
- Update all the modules (including dev) with `./local/exec.sh -w /srv/www site composer update`.
- Add a module with `./local/exec.sh -w /srv/www site composer require site/some-module`.
- Remove a module with `./local/exec.sh -w /srv/www site composer remove site/some-module`.

## Debugging core or a contrib module/theme

Enter the container with `./local/exec.sh -w /srv/www site sh` and edit files with `vi` for example.

Alternatively clone the core or contrib module/theme somewhere and mount the relevant folder/files by editing the `local/docker-compose.yml` file.

Ex: `"../contrib-module-repo/:/srv/www/html/modules/contrib/contrib-module-name:rw"`.

## Local proxy

Check the [setup-notes](https://github.com/UN-OCHA/local-reverse-proxy/blob/main/setup-notes.md) for first-time set-up of a local reverse proxy.
