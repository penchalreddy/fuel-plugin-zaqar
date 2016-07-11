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
# qaas_zaqar::openstack_haproxy_zaqar

class qaas_zaqar::openstack_haproxy_zaqar {

  notice('MODULAR: qaas_zaqar/openstack_haproxy_zaqar.pp')


  $zaqar          = hiera_hash('fuel-plugin-zaqar', undef)
  $zaqar_enabled  = pick($zaqar['metadata']['enabled'], false)

  if ($zaqar_enabled) {

    $network_metadata   = hiera_hash('network_metadata', {})
    $public_ssl_hash    = hiera_hash('public_ssl', {})
    $ssl_hash           = hiera_hash('use_ssl', {})

    $public_ssl         = get_ssl_property($ssl_hash, $public_ssl_hash, 'zaqar', 'public', 'usage', false)
    $public_ssl_path    = get_ssl_property($ssl_hash, $public_ssl_hash, 'zaqar', 'public', 'path', [''])

    $internal_ssl       = get_ssl_property($ssl_hash, {}, 'zaqar', 'internal', 'usage', false)
    $internal_ssl_path  = get_ssl_property($ssl_hash, {}, 'zaqar', 'internal', 'path', [''])

    $external_lb        = hiera('external_lb', false)
    $zaqar_nodes       = get_nodes_hash_by_roles($network_metadata, ['primary-zaqar', 'zaqar'])

    $zaqar_api_port    = hiera($zaqar['zaqar_api_port'], 9001)

    if (!$external_lb) {

      $zaqar_address_map  = get_node_to_ipaddr_map_by_network_role($zaqar_nodes, 'zaqar/api')
      $server_names        = keys($zaqar_address_map)
      $ipaddresses         = values($zaqar_address_map)
      $public_virtual_ip   = hiera('public_vip')
      $internal_virtual_ip = hiera('management_vip')

      # configure zaqar ha proxy
      Openstack::Ha::Haproxy_service {
        internal_virtual_ip => $internal_virtual_ip,
        ipaddresses         => $ipaddresses,
        public_virtual_ip   => $public_virtual_ip,
        server_names        => $server_names,
        public              => true,
        internal_ssl        => $internal_ssl,
        internal_ssl_path   => $internal_ssl_path,
      }

      openstack::ha::haproxy_service { 'zaqar-api':
        order                  => '511',
        listen_port            => $zaqar_api_port,
        public_ssl             => $public_ssl,
        public_ssl_path        => $public_ssl_path,
        #require_service        => 'zaqar-api',
        haproxy_config_options => {
          option           => ['httpchk', 'httplog', 'httpclose'],
          'timeout server' => '660s',
          'http-request'   => 'set-header X-Forwarded-Proto https if { ssl_fc }',
        },
        balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
      }

    }
  }
}

