#!/usr/bin/env bash

set -e

# Usage.
usage() {
  echo "Usage: ./scripts/setup.sh 'site.prod.url' 'Site Name' 'project-name' " >&2
  echo "---" >&2
  echo "Example: ./scripts/setup.sh 'my-website.org' 'My Website' 'my-website' " >&2
  exit 1
}

if [ "$1" = "" ] || [ "$2" = "" ] || [ "$3" = "" ]; then
  usage
fi

exclude_pattern="^((.git/)|(README.md)|(scripts/setup.sh))"
site_name_pattern="Starterkit"
site_url_pattern="starterkit.prod"
project_name_pattern="starterkit"

site_url="$1"
site_name="$2"
project_name="$3"

grep -r -l "$site_url_pattern" * .[^.]* | grep -v -E "$exclude_pattern" | xargs sed -i "s/$site_url_pattern/$site_url/g"
grep -r -l "$site_name_pattern" * .[^.]* | grep -v -E "$exclude_pattern" | xargs sed -i "s/$site_name_pattern/$site_name/g"
grep -r -l "$project_name_pattern" * .[^.]* | grep -v -E "$exclude_pattern" | xargs sed -i "s/$project_name_pattern/$project_name/g"

cp ./assets/docker-build-image.yml .github/workflows/docker-build-image.yml
