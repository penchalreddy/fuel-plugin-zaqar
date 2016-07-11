#
# Copyright (C) 2016 AT&T Inc, Services.
#
# Author: Shaik Apsar
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# caas_zaqar::keystone

class qaas_zaqar::keystone {

  notice('MODULAR: qaas_zaqar/keystone')

  $zaqar          = hiera_hash('fuel-plugin-zaqar', undef)
  $zaqar_enabled  = pick($zaqar['metadata']['enabled'], false)

  if ($zaqar_enabled) {

    $management_vip     = hiera('management_vip')
    $public_ssl_hash    = hiera_hash('public_ssl', {})
    $ssl_hash           = hiera_hash('use_ssl', {})
    $public_vip         = hiera('public_vip')

    $public_protocol     = get_ssl_property($ssl_hash, $public_ssl_hash, 'zaqar', 'public', 'protocol', 'http')
    $public_address      = get_ssl_property($ssl_hash, $public_ssl_hash, 'zaqar', 'public', 'hostname', [$public_vip])

    $internal_protocol   = get_ssl_property($ssl_hash, {}, 'zaqar', 'internal', 'protocol', 'http')
    $internal_address    = get_ssl_property($ssl_hash, {}, 'zaqar', 'internal', 'hostname', [$management_vip])

    $admin_protocol      = get_ssl_property($ssl_hash, {}, 'zaqar', 'admin', 'protocol', 'http')
    $admin_address       = get_ssl_property($ssl_hash, {}, 'zaqar', 'admin', 'hostname', [$management_vip])

    $region              = pick($zaqar['region'], hiera('region', 'RegionOne'))
    $password            = $zaqar['auth_password']
    $auth_name           = pick($zaqar['auth_name'], 'zaqar')
    $email               = pick($zaqar['email'], 'zaqar@localhost')
    $configure_user      = pick($zaqar['configure_user'], true)
    $configure_user_role = pick($zaqar['configure_user_role'], true)
    $configure_endpoint  = pick($zaqar['configure_endpoint'], true)
    $service_name        = pick($zaqar['service_name'], 'zaqar')
    $tenant              = pick($zaqar['tenant'], 'services')

    validate_string($public_address)
    validate_string($password)

    $bind_port = '9001'

    $public_url          = "${public_protocol}://${public_address}:${bind_port}/v1"
    $internal_url        = "${internal_protocol}://${internal_address}:${bind_port}/v1"
    $admin_url           = "${admin_protocol}://${admin_address}:${bind_port}/v1"

    Class['::osnailyfacter::wait_for_keystone_backends']
      -> Class['::zaqar::keystone::auth']

    class {'::osnailyfacter::wait_for_keystone_backends': }

    class { '::zaqar::keystone::auth':
      configure_user      => $configure_user,
      configure_user_role => $configure_user_role,
      configure_endpoint  => $configure_endpoint,
      service_name        => $service_name,
      region              => $region,
      auth_name           => $auth_name,
      password            => $password,
      email               => $email,
      tenant              => $tenant,
      public_url          => $public_url,
      internal_url        => $internal_url,
      admin_url           => $admin_url,
    }

  }
}
