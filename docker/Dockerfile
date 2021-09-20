# Build the code.
FROM public.ecr.aws/unocha/unified-builder:8.0-stable as builder

ARG  BRANCH_ENVIRONMENT
ENV  NODE_ENV=$BRANCH_ENVIRONMENT

COPY . /srv/www
WORKDIR /srv/www

# Clean up previous composer installation and run new one.
RUN rm -rf ./vendor && \
    composer self-update --2 && \
    COMPOSER_MEMORY_LIMIT=-1 composer install --no-interaction --prefer-dist && \
    # Build theme assets once you have a theme!
    # composer run sass && \
    COMPOSER_MEMORY_LIMIT=-1 composer install --no-dev --no-interaction --prefer-dist

# Copy settings to default site location after creating it.
RUN mkdir -m 0775 -p html/sites/default && \
    cp -a docker/settings.php docker/services.yml html/sites/default

################################################################################

# Generate the image.
FROM public.ecr.aws/unocha/php-k8s:8.0-NR-stable

ARG VCS_REF
ARG VCS_URL
ARG BUILD_DATE
ARG GITHUB_ACTOR
ARG GITHUB_REPOSITORY
ARG GITHUB_SHA
ARG GITHUB_REF

ENV  NGINX_SERVERNAME=starterkit.dev \
     PHP_ENVIRONMENT=production \
     PHP_MEMORY_LIMIT=128M \
     PHP_MAX_CHILDREN=16 \
     GIT_BLAME=$GITHUB_ACTOR \
     GIT_REPO=$GITHUB_REPOSITORY \
     GIT_SHA=$GITHUB_SHA \
     GIT_REF=$GITHUB_REF \
     PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/srv/www/vendor/bin

LABEL info.humanitarianresponse.build.date=$BUILD_DATE \
      info.humanitarianresponse.build.vcs-url=$VCS_URL \
      info.humanitarianresponse.build.vcs-ref=$VCS_REF

COPY --from=builder /srv/www/config /srv/www/config/
COPY --from=builder /srv/www/html /srv/www/html/
COPY --from=builder /srv/www/vendor /srv/www/vendor/
COPY --from=builder /srv/www/composer.json /srv/www/composer.json
COPY --from=builder /srv/www/composer.patches.json /srv/www/composer.patches.json
COPY --from=builder /srv/www/composer.lock /srv/www/composer.lock
COPY --from=builder /srv/www/docker/etc/nginx/apps/drupal/fastcgi_drupal.conf /etc/nginx/apps/drupal/fastcgi_drupal.conf
