# Drupal Starter Kit

**Drupal 10 version**

This is a sample Drupal site repository. It contains all the basics to get you started with a brand new Drupal 10 site that uses the [UN-OCHA Common Design theme](https://github.com/UN-OCHA/common_design).

See https://humanitarian.atlassian.net/browse/OPS-7611

Use `composer create-project` to install after cloning or `composer create-project unocha/starterkit`

Then run `scripts/setup.sh` (see [What to change?](#what-to-change) below).

*The Drupal 9 version is in the [D9](tree/D9) branch.*

## What to change?

Several files need to be changed to replace `starterkit` with your project name etc.

You can run the `scripts/setup.sh` script to do that for you.

```sh
./scripts/setup.sh "site.prod.url" "Site Name" "project-name"
```
For example, for Common Design site:
```sh
./scripts/setup.sh "web.brand.unocha.org" "Common Design" "common-design-site"
```

The setup script will also copy a github action to build docker images on `develop`, `feature` and `main` branches.

### README

Well, obviously, this [README](README.md) file needs to be updated with information relevant to your project.

### Github workflows

Edit the following files, replacing `starterkit` with your project name (ex: `my-website`):

- [.github/workflows/docker-build-image.yml](.github/workflows/docker-build-image.yml)

### Docker

Edit the following files:

- [docker/Dockerfile](docker/Dockerfile) --> change `starterkit.prod` to your **production** site URL.
- [Makefile](Makefile) --> change `starterkit` to your project name (ex: `my-website`).

### Composer

Edit the `composer.json` file with your project name, authors etc.

Use `composer require package` and `composer remove package` to add/remove packages (ex: `drupal/group`).

- [composer.json](composer.json)

### Tests

Edit the following files, replacing `starterkit` with your project name (ex: `my-website`):

- [.travis.yml](.travis.yml)
- [phpunit.xml](phpunit.xml)
- [tests/docker-compose.yml](tests/docker-compose.yml)
- [tests/settings/settings.test.php](tests/settings/settings.test.php)
- [tests/test.sh](tests/test.sh)

### Site configuration

Edit the Drupal site configuration to set up the site name (can be done via the Drupal UI as well).

- [config/system.site.yml](config/system.site.yml)

### Local stack

See the [Running the site](#running-the-site) section below.

- [local/docker-compose.yml](local/docker-compose.yml)
- [local/install.sh](local/install.sh)
- [local/shared/settings/settings.local.php](local/shared/settings/settings.local.php)

## Recommended modules

Here's a list of commonly used modules among the UN-OCHA websites.

### Paragraphs

Many UN-OCHA websites use the `paragraphs` module and related ones to structure the content of the site.

- https://www.drupal.org/project/paragraphs
- https://www.drupal.org/project/layout_paragraphs

*This is enabled by default as of 2023-01-19.*

### XML Sitemap

To help search engines index your website, the `xmlsitemap` can help generate and submit a site map of your content.

- https://www.drupal.org/project/xmlsitemap

*This is enabled by default as of 2023-01-19 but no sitemap is configured.*

**Note:** you may want to edit the [assets/robots.txt.append](assets/robots.txt.append) file to indicate the URL of your sitemap:

```
# Sitemap
Sitemap: https://my-website-domain/sitemap.xml
```

### Groups

The `group` and related modules help create collections of content and users with specific access control permissions.

- https://www.drupal.org/project/group
- https://www.drupal.org/project/subgroup

### Theme switcher

The `theme_switcher` module helps control which theme to use on which pages.

- https://www.drupal.org/project/theme_switcher

### Field groups

The `field_group` module helps organizing fields in a form.

- https://www.drupal.org/project/field_group

## Patches

See the [patches/notes.md](patches/notes.md) about Drupal 10 compatibility patches etc.

## Running the site

You should create a proper standard environment stack to run your site.

But in the meantime the [local](local) directory contains what is necessary to quickly create a set of containers to run your site locally.

Run `./local/install.sh -h` to see the script options.

## Updating this repository

1. Update dependendices etc. in the [composer.json](composer.json) file
2. Create a local instance by running `./local/install.sh -m -i -c`
3. Log in this new instance and enable/disable/configure the modules and site
4. Export the configuration (ex: `docker exec -it starterkit-local-site drush cex`)
5. Create a Pull Request with the changes
6. Stop and remove the containers with `./local/install.sh -x -v`

**Note:** do not forget to set up your local proxy to manage the `starterkit-local.test` domain.
