notice('MODULAR: zaqar/haproxy.pp')

$zaqar_hash    = hiera_hash('fuel-plugin-zaqar', {})
$public_ssl_hash = hiera('public_ssl')
$network_metadata = hiera_hash('network_metadata')

$use_zaqar = pick($zaqar_hash['metadata']['enabled'], true)


$zaqar_address_map = get_node_to_ipaddr_map_by_network_role(get_nodes_hash_by_roles($network_metadata, ['zaqar']), 'zaqar/api')

if ($use_zaqar) {
  $server_names        = pick(hiera_array('zaqar_names', undef),
                              keys($zaqar_address_map))
  $ipaddresses         = pick(hiera_array('zaqar_ipaddresses', undef),
                              values($zaqar_address_map))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  # configure designate ha proxy
  Openstack::Ha::Haproxy_service {
    ipaddresses            => $ipaddresses,
    public_virtual_ip      => $public_virtual_ip,
    server_names           => $server_names,
    public                 => true,
    public_ssl             => $public_ssl_hash['services'],
    haproxy_config_options => {
      option => ['httpchk GET /', 'httplog','httpclose'],
    },
  }

  openstack::ha::haproxy_service { 'zaqar-api':
    order               => '230',
    listen_port         => 8888,
    internal_virtual_ip => $internal_virtual_ip,
  }

}
