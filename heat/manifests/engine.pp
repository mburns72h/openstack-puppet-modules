# == Class: heat::engine
#
#  Installs & configure the heat engine service
#
# === Parameters
# [*auth_encryption_key*]
#   (required) Encryption key used for authentication info in database
#   Must be either 16, 24, or 32 bytes long.
#
# [*package_ensure*]
#    (Optional) Ensure state for package.
#    Defaults to 'present'
#
# [*enabled*]
#   (optional) Should the service be enabled.
#   Defaults to 'true'
#
# [*manage_service*]
#   (optional) Whether the service should be managed by Puppet.
#   Defaults to true.
#
# [*heat_stack_user_role*]
#   (optional) Keystone role for heat template-defined users
#   Defaults to 'heat_stack_user'
#
# [*heat_metadata_server_url*]
#   (optional) URL of the Heat metadata server
#   Defaults to 'http://127.0.0.1:8000'
#
# [*heat_waitcondition_server_url*]
#   (optional) URL of the Heat waitcondition server
#   Defaults to 'http://127.0.0.1:8000/v1/waitcondition'
#
# [*heat_watch_server_url*]
#   (optional) URL of the Heat cloudwatch server
#   Defaults to 'http://127.0.0.1:8003'
#
# [*engine_life_check_timeout*]
#   (optional) RPC timeout (in seconds) for the engine liveness check that is
#   used for stack locking
#   Defaults to '2'
#
# [*deferred_auth_method*]
#   (optional) Select deferred auth method.
#   Can be "password" or "trusts".
#   Defaults to 'trusts'
#
# [*trusts_delegated_roles*]
#   (optional) Array of trustor roles to be delegated to heat.
#   This value is also used by heat::keystone::auth if it is set to
#   configure the keystone roles.
#   Defaults to ['heat_stack_owner']
#
# === Deprecated Parameters
#
# [*configure_delegated_roles*]
#   (optional) Whether to configure the delegated roles.
#   Defaults to true
#   Deprecated: Moved to heat::keystone::auth, will be removed in a future release.
#
class heat::engine (
  $auth_encryption_key,
  $package_ensure                = 'present',
  $manage_service                = true,
  $enabled                       = true,
  $heat_stack_user_role          = 'heat_stack_user',
  $heat_metadata_server_url      = 'http://127.0.0.1:8000',
  $heat_waitcondition_server_url = 'http://127.0.0.1:8000/v1/waitcondition',
  $heat_watch_server_url         = 'http://127.0.0.1:8003',
  $engine_life_check_timeout     = '2',
  $deferred_auth_method          = 'trusts',
  $trusts_delegated_roles        = ['heat_stack_owner'],  #DEPRECATED
  $configure_delegated_roles     = true,                  #DEPRECATED
) {

  # Validate Heat Engine AES key
  # must be either 16, 24, or 32 bytes long
  # https://bugs.launchpad.net/heat/+bug/1415887
  $allowed_sizes = ['16','24','32']
  $param_size = size($auth_encryption_key)
  if ! (member($allowed_sizes, "${param_size}")) { # lint:ignore:only_variable_string
    fail("${param_size} is not a correct size for auth_encryption_key parameter, it must be either 16, 24, 32 bytes long.")
  }

  include ::heat
  include ::heat::params

  Heat_config<||> ~> Service['heat-engine']

  Package['heat-engine'] -> Heat_config<||>
  Package['heat-engine'] -> Service['heat-engine']
  package { 'heat-engine':
    ensure => $package_ensure,
    name   => $::heat::params::engine_package_name,
    tag    => 'openstack',
    notify => $::heat::subscribe_sync_db,
  }

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  if $configure_delegated_roles {
    warning ('configure_delegated_roles is deprecated in this class, use heat::keystone::auth')
    keystone_role { $trusts_delegated_roles:
      ensure => present,
    }
  }

  service { 'heat-engine':
    ensure     => $service_ensure,
    name       => $::heat::params::engine_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    require    => [ File['/etc/heat/heat.conf'],
                    Package['heat-common'],
                    Package['heat-engine']],
    subscribe  => $::heat::subscribe_sync_db,
  }

  heat_config {
    'DEFAULT/auth_encryption_key'          : value => $auth_encryption_key;
    'DEFAULT/heat_stack_user_role'         : value => $heat_stack_user_role;
    'DEFAULT/heat_metadata_server_url'     : value => $heat_metadata_server_url;
    'DEFAULT/heat_waitcondition_server_url': value => $heat_waitcondition_server_url;
    'DEFAULT/heat_watch_server_url'        : value => $heat_watch_server_url;
    'DEFAULT/engine_life_check_timeout'    : value => $engine_life_check_timeout;
    'DEFAULT/trusts_delegated_roles'       : value => $trusts_delegated_roles;
    'DEFAULT/deferred_auth_method'         : value => $deferred_auth_method;
  }
}
