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
# qaas_zaqar::zaqar

class qaas_zaqar::zaqar {

  notice('MODULAR: qaas_zaqar/zaqar')

  $zaqar          = hiera_hash('fuel-plugin-zaqar', undef)
  $zaqar_enabled  = pick($zaqar['metadata']['enabled'], false)

  if ($zaqar_enabled) {

    prepare_network_config(hiera('network_scheme', {}))

    $access_hash                = hiera_hash('access', {})
    $keystone_hash              = hiera_hash('keystone', {})
    $public_vip                 = hiera('public_vip')
    $database_vip               = hiera('database_vip')
    $management_vip             = hiera('management_vip')
    $region                     = hiera('region', 'RegionOne')
    $service_endpoint           = hiera('service_endpoint')
    $debug                      = hiera('debug', false)
    $verbose                    = hiera('verbose', true)
    $use_syslog                 = hiera('use_syslog', true)
    $use_stderr                 = hiera('use_stderr', false)
    $rabbit_ha_queues           = hiera('rabbit_ha_queues')
    $amqp_port                  = hiera('amqp_port')
    $amqp_hosts                 = hiera('amqp_hosts')
    $public_ssl_hash            = hiera_hash('public_ssl', {})
    $ssl_hash                   = hiera_hash('use_ssl', {})
    $external_dns               = hiera_hash('external_dns', {})
    $external_lb                = hiera('external_lb', false)
    $max_retries                = hiera('max_retries')
    $max_pool_size              = hiera('max_pool_size')
    $max_overflow               = hiera('max_overflow')
    $idle_timeout               = hiera('idle_timeout')

    $identity_api_version       = '3'

    $internal_auth_protocol     = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
    $internal_auth_address      = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [hiera('keystone_endpoint', ''), $service_endpoint, $management_vip])
    $auth_uri                   = "${internal_auth_protocol}://${internal_auth_address}:5000/"
    $zaqar_auth_uri            = "${auth_uri}v${identity_api_version}"

    $admin_auth_protocol        = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
    $admin_auth_address         = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [hiera('keystone_endpoint', ''), $service_endpoint, $management_vip])
    $identity_uri               = "${admin_auth_protocol}://${admin_auth_address}:35357/"

    $public_protocol            = get_ssl_property($ssl_hash, $public_ssl_hash, 'zaqar', 'public', 'protocol', 'http')
    $public_address             = get_ssl_property($ssl_hash, $public_ssl_hash, 'zaqar', 'public', 'hostname', [$public_vip])

    $internal_protocol          = get_ssl_property($ssl_hash, {}, 'zaqar', 'internal', 'protocol', 'http')
    $internal_address           = get_ssl_property($ssl_hash, {}, 'zaqar', 'internal', 'hostname', [$management_vip])

    $admin_protocol             = get_ssl_property($ssl_hash, {}, 'zaqar', 'admin', 'protocol', 'http')
    $admin_address              = get_ssl_property($ssl_hash, {}, 'zaqar', 'admin', 'hostname', [$management_vip])

    $haproxy_stats_url = "http://${service_endpoint}:10000/;csv"

    $zaqar_endpoint_type       = pick($zaqar['zaqar_endpoint_type'], 'internalURL')
    $heat_endpoint_type         = pick($zaqar['heat_endpoint_type'], 'internalURL')
    $glance_endpoint_type       = pick($zaqar['glance_endpoint_type'], 'internalURL')
    $barbican_endpoint_type     = pick($zaqar['barbican_endpoint_type'], 'internalURL')
    $nova_endpoint_type         = pick($zaqar['nova_endpoint_type'], 'internalURL')
    $cinder_endpoint_type       = pick($zaqar['cinder_endpoint_type'], 'internalURL')
    $neutron_endpoint_type      = pick($zaqar['neutron_endpoint_type'], 'internalURL')


    $public_url                 = "${public_protocol}://${public_address}:${bind_port}/v1"
    $internal_url               = "${internal_protocol}://${internal_address}:${bind_port}/v1"
    $admin_url                  = "${admin_protocol}://${admin_address}:${bind_port}/v1"

    $db_user                    = pick($zaqar['db_user'], 'zaqar')
    $db_name                    = pick($zaqar['db_name'], 'zaqar')
    $db_password                = $zaqar['db_password']
    $read_timeout               = '60'
    $db_connection              = "mysql://${db_user}:${db_password}@${database_vip}/${db_name}?read_timeout=${read_timeout}"

    $rabbit_username            = hiera( $zaqar['rabbit_user'], 'zaqar')
    $rabbit_password            = $zaqar['rabbit_password']

    $zaqar_admin_password      = $zaqar['auth_password']
    $zaqar_admin_user          = pick($zaqar['auth_name'], 'zaqar')
    $zaqar_admin_tenant_name   = pick($zaqar['tenant'], 'services')

    $bind_host                  = get_network_role_property('zaqar/api', 'ipaddr')

    $domain_name                = pick($zaqar['domain_name'], 'zaqar')
    $domain_admin               = pick($zaqar['domain_admin'], 'zaqar_admin')
    $domain_admin_email         = pick($zaqar['domain_admin_email'], 'zaqar_admin@localhost')
    $domain_password            = $zaqar['domain_password']

    $admin_token                = $keystone_hash['admin_token']
    $admin_tenant               = $access_hash['tenant']
    $admin_email                = $access_hash['email']
    $admin_user                 = $access_hash['user']
    $admin_password             = $access_hash['password']

    validate_string($domain_password)

    $murano_settings_hash = hiera_hash('murano_settings', {})
    if has_key($murano_settings_hash, 'murano_repo_url') {
      $murano_repo_url = $murano_settings_hash['murano_repo_url']
    } else {
      $murano_repo_url = 'http://storage.apps.openstack.org'
    }


    class { '::osnailyfacter::wait_for_keystone_backends':}



    class { '::zaqar':
      auth_uri          => $zaqar_auth_uri,
      identity_uri      => $identity_uri,
      admin_password    => $zaqar_admin_password,
      admin_user        => $zaqar_admin_user,
      admin_tenant_name => $zaqar_admin_tenant_name,
    }



    class { '::zaqar::transport::websocket': }

    class { '::zaqar::transport::wsgi': }

    class { '::zaqar::logging': }

    class { '::zaqar::policy': }

    class { '::zaqar::server': }

    class { 'zaqar::management::mongodb':
      uri    => $uri_auth
    }

    class { 'zaqar::messaging::mongodb':
      uri    => $uri_auth
    }
  }
}

