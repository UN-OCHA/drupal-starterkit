# Local stack

The `local` folder contains a script and docker/drupal configuration to create an instance of the site locally.

## Setup

1. Rename `local/.env.example` to `local/.env` and edit it to adjust the environement variables. The default should be enough.
2. Rename `local/shared/settings/settings.site.php.example` to `local/shared/settings/settings.site.php` and edit it to adjust the settings.

## Scripts

**Important:** Run the script from the root of the repository.

The script `./local/install.sh -h` is used to create/stop/remove containers etc. Run `./local/install.sh -h` to see the script options.

The script `./local/exec.sh` is a shortcut for `docker compose -f local/docker-compose.yml exec`

## Create instance

1. Run `./local/install.sh -m -c -i` to create an instance of the site (empty database) from the existing config.
2. Run `./local/exec.sh -T -u appuser site drush sqlc < path-to-db-dump.sql` to restore a database dump.
3. Run `./local/install.sh -d` to install the dev dependencies, import the config and update the database.

## Composer

- Install all the modules (including dev) with `./local/exec.sh -w /srv/www site composer install`.
- Update all the modules (including dev) with `./local/exec.sh -w /srv/www site composer update`.
- Add a module with `./local/exec.sh -w /srv/www site composer require site/some-module`.
- Remove a module with `./local/exec.sh -w /srv/www site composer remove site/some-module`.

## Debugging core or a contrib module/theme

Enter the container with `./local/exec.sh -w /srv/www site sh` and edit files with `vi` for example.

Alternatively clone the core or contrib module/theme somewhere and mount the relevant folder/files by editing the `local/docker-compose.yml` file.

## Local proxy

Check the [setup-notes](https://github.com/UN-OCHA/local-reverse-proxy/blob/main/setup-notes.md) for first-time set-up of a local reverse proxy.
