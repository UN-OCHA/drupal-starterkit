<?php

/**
 * @file
 * Memcache configuration.
 */

// Memcache.
if (file_exists('sites/default/memcache.services.yml')) {
  // Add our memcache services definitions. This file is added by the docker build.
  $settings['container_yamls'][] = 'sites/default/memcache.services.yml';
  // Add our memcache services definitions.
  if (file_exists('modules/contrib/memcache/memcache.services.yml')) {
    $settings['container_yamls'][] = 'modules/contrib/memcache/memcache.services.yml';
  }
  else if (file_exists('modules/memcache/memcache.services.yml')) {
    $settings['container_yamls'][] = 'modules/memcache/memcache.services.yml';
  }
  // Configure memcache.
  $settings['memcache']['servers']    = ['memcache:11211' => 'default'];
  $settings['memcache']['bins']       = ['default' => 'default'];
  $settings['memcache']['key_prefix'] = 'starterkit-local';
  $settings['cache']['default']       = 'cache.backend.memcache';

  // Performance tweaks.
  $settings['memcache']['options'] = [
    Memcached::OPT_COMPRESSION => TRUE,
    Memcached::OPT_DISTRIBUTION => Memcached::DISTRIBUTION_CONSISTENT,
  ];

  // Stick the bootstrap container in memcache, too!
  $class_loader->addPsr4('Drupal\\memcache\\', 'modules/contrib/memcache/src');

  // Define custom bootstrap container definition to use Memcache for cache.container.
  $settings['bootstrap_container_definition'] = [
    'parameters' => [],
    'services' => [
      # Dependencies.
      'settings' => [
        'class' => 'Drupal\Core\Site\Settings',
        'factory' => 'Drupal\Core\Site\Settings::getInstance',
      ],
      'request_stack' => [
        'class' => 'Drupal\Core\Http\RequestStack',
        'tags' => ['name' => 'persist'],
      ],
      'datetime.time' => [
        'class' => 'Drupal\Component\Datetime\Time',
        'arguments' => ['@request_stack'],
      ],
      'memcache.settings' => [
        'class' => 'Drupal\memcache\MemcacheSettings',
        'arguments' => ['@settings'],
      ],
      'memcache.factory' => [
        'class' => 'Drupal\memcache\Driver\MemcacheDriverFactory',
        'arguments' => ['@memcache.settings'],
      ],
      'memcache.timestamp.invalidator.bin' => [
        'class' => 'Drupal\memcache\Invalidator\MemcacheTimestampInvalidator',
        # Adjust tolerance factor as appropriate when not running memcache on localhost.
        'arguments' => ['@memcache.factory', 'memcache_bin_timestamps', 0.001],
      ],
      'memcache.timestamp.invalidator.tag' => [
        'class' => 'Drupal\memcache\Invalidator\MemcacheTimestampInvalidator',
        # Remember to update your main service definition in sync with this!
        # Adjust tolerance factor as appropriate when not running memcache on localhost.
        'arguments' => ['@memcache.factory', 'memcache_tag_timestamps', 0.001],
      ],
      'memcache.backend.cache.container' => [
        'class' => 'Drupal\memcache\DrupalMemcacheInterface',
        'factory' => ['@memcache.factory', 'get'],
        # Actual cache bin to use for the container cache.
        'arguments' => ['container'],
      ],
      # Define a custom cache tags invalidator for the bootstrap container.
      'cache_tags_provider.container' => [
        'class' => 'Drupal\memcache\Cache\TimestampCacheTagsChecksum',
        'arguments' => ['@memcache.timestamp.invalidator.tag'],
      ],
      'cache.container' => [
        'class' => 'Drupal\memcache\MemcacheBackend',
        'arguments' => ['container', '@memcache.backend.cache.container', '@cache_tags_provider.container', '@memcache.timestamp.invalidator.bin', '@datetime.time'],
      ],
    ],
  ];
}
