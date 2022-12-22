<?php

namespace scripts\composer;

use Composer\Package\CompletePackage;
use Composer\Package\Link;
use Composer\Package\PackageInterface;
use Composer\Package\RootPackage;
use Composer\Plugin\PrePoolCreateEvent;
use Composer\Semver\Constraint\ConstraintInterface;
use Composer\Semver\VersionParser;

/**
 * Ease compatibility of modules.
 *
 * This is basically a scripted version of the `mglaman/composer-drupal-lenient`
 * plugin so that we don't need the double step of having to install the plugin
 * to be able to add Drupal 10 incompatible mdoules.
 *
 * @see https://github.com/mglaman/composer-drupal-lenient
 */
class DrupalLenientRequirement {

  /**
   * Drupal version constraint.
   *
   * @var \Composer\Semver\Constraint\ConstraintInterface
   */
  private static ConstraintInterface $constraint;

  /**
   * List of packages to which apply the lenient requirement.
   *
   * @var array
   */
  private static array $allowedList;

  /**
   * Return the root package from a list of packages.
   */
  private static function getRootPackage(array $packages) {
    foreach ($packages as $package) {
      if ($package instanceof RootPackage) {
        return $package;
      }
    }
    return NULL;
  }

  /**
   * Load the settings for this script from the root package.
   *
   * @param \Composer\Package\PackageInterface|null $root_package
   *   Composer root package.
   *
   * @return bool
   *   TRUE if the settings were found and loaded.
   */
  private static function loadSettings(?PackageInterface $root_package): bool {
    if (!isset($root_package)) {
      return FALSE;
    }

    $extra = $root_package->getExtra();
    if (!isset($extra)) {
      return FALSE;
    }

    // Retrieve the configuration.
    $settings = $extra['drupal-lenient'] ?? [];
    if (!is_array($settings) || empty($settings)) {
      return FALSE;
    }

    // Retrieve the Drupal version constraint.
    $constraint = $settings['constraint'];
    if (!is_string($constraint) || empty($constraint)) {
      return FALSE;
    }
    elseif (!isset(static::$constraint)) {
      static::$constraint = (new VersionParser())
        ->parseConstraints($constraint);
    }

    // Retrieve the list of modules for which to apply lenient requirements.
    $list = $settings['allowed-list'];
    if (!is_array($list) || empty($list)) {
      return FALSE;
    }
    else {
      static::$allowedList = $settings['allowed-list'];
    }
    return TRUE;
  }

  /**
   * Script entry function.
   */
  public static function changeVersionConstraint(PrePoolCreateEvent $event): void {
    if (!static::loadSettings(static::getRootPackage($event->getPackages()))) {
      return;
    }

    // Check the package and update the requirements if appropriate.
    $packages = $event->getPackages();
    /** @var \Composer\Package\PackageInterface $package */
    foreach ($packages as $package) {
      if (static::applies($package)) {
        static::adjust($package);
      }
    }
    $event->setPackages($packages);
  }

  /**
   * Check if the lenient requirement should be applied to the given package.
   *
   * @param \Composer\Package\PackageInterface $package
   *   Package.
   *
   * @return bool
   *   TRUE if the requirement adjustement should apply to this package.
   */
  private static function applies(PackageInterface $package): bool {
    return static::isDrupalPackage($package) && in_array($package->getName(), static::$allowedList, TRUE);
  }

  /**
   * Adjust the package requirements.
   *
   * @param \Composer\Package\PackageInterface $package
   *   Package for which to adjust the Drupal version constraint.
   */
  private static function adjust(PackageInterface $package): void {
    $requires = array_map(function (Link $link) {
      if ($link->getDescription() === Link::TYPE_REQUIRE && $link->getTarget() === 'drupal/core') {
        return new Link(
            $link->getSource(),
            $link->getTarget(),
            static::$constraint,
            $link->getDescription(),
            static::$constraint->getPrettyString()
        );
      }
      return $link;
    }, $package->getRequires());

    // @note `setRequires` is on Package but not PackageInterface.
    if ($package instanceof CompletePackage) {
      $package->setRequires($requires);
    }
  }

  /**
   * Check if a package is a non core Drupal package.
   *
   * @param \Composer\Package\PackageInterface $package
   *   Package.
   *
   * @return bool
   *   TRUE in case of a non core Drupal package.
   */
  private static function isDrupalPackage(PackageInterface $package): bool {
    $type = $package->getType();
    return $type !== 'drupal-core' && str_starts_with($type, 'drupal-');
  }

}
