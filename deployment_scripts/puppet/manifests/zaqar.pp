notice('MODULAR: zaqar/zaqar.pp')

$zaqar_hash             = hiera_hash('fuel-plugin-zaqar', {})
$public_vip                 = hiera('public_vip')
$management_vip             = hiera('management_vip')
$database_vip               = hiera('database_vip', $management_vip)
$public_ssl_hash            = hiera('public_ssl')
$mysql_hash                 = hiera_hash('mysql_hash', {})

$network_metadata           = hiera_hash('network_metadata', {})

$public_address = $public_ssl_hash['services'] ? {
  true    => $public_ssl_hash['hostname'],
  default => $public_vip,
}
$public_protocol = $public_ssl_hash['services'] ? {
  true    => 'https',
  default => 'http',
}

$debug                      = hiera('debug', true)
$verbose                    = hiera('verbose', true)
$rabbit_hash                = hiera_hash('rabbit_hash', {})
$rabbit_ha_queues           = hiera('rabbit_ha_queues')
$amqp_hosts                 = hiera('amqp_hosts')
$rabbit_hosts               = split($amqp_hosts, ',')

$db_host                    = pick($zaqar_hash['metadata']['db_host'], $database_vip)
$db_user                    = pick($zaqar_hash['metadata']['db_user'], 'zaqar')
$db_name                    = pick($zaqar_hash['metadata']['db_name'], 'zaqar')
$db_password                = pick($zaqar_hash['metadata']['db_password'], 'zaqar')
$database_connection        = "mysql://${db_user}:${db_password}@${db_host}/${db_name}?charset=utf8&read_timeout=60"

$zaqar_auth_strategy    = "keystone"
$uri_auth                = mongodb://127.0.0.1:27017
$keystone_endpoint          = hiera('service_endpoint', $management_vip)
$zaqar_tenant           = pick($zaqar_hash['metadata']['tenant'],'services')
$zaqar_user             = pick($zaqar_hash['metadata']['user'],'zaqar')
$zaqar_user_password    = pick($zaqar_hash['metadata']['user_password'],'zaqar')
$enable_api_v2              = hiera('enable_api_v2', true)

if $zaqar_hash['metadata']['enabled'] {
  class { 'zaqar':
    verbose             => $verbose,
    debug               => $debug,
    rabbit_hosts        => $rabbit_hosts,
    rabbit_port         => $rabbit_port,
    rabbit_userid       => $rabbit_hash['user'],
    rabbit_password     => $rabbit_hash['password'],
  }

  class { 'zaqar::config': }

  class { 'zaqar::db':
    database_connection => $database_connection,
  }

  class { 'zaqar::logging': }

  class { 'zaqar::policy': }

  class { 'zaqar::server': }

  class { 'zaqar::management::mongodb':
    uri    => $uri_auth
  }
 
  class { 'zaqar::messaging::mongodb':
    uri    => $uri_auth
  }
  
  class { 'zaqar::transport::websocket': }

  class { 'zaqar::transport::wsgi': }

  class { 'zaqar::api':
    auth_strategy        => $zaqar_auth_strategy,
    keystone_host        => $keystone_endpoint,
    keystone_protocol    => $public_protocol,
    keystone_tenant      => $zaqar_tenant,
    keystone_user        => $zaqar_user,
    keystone_password    => $zaqar_user_password,
    enable_api_v2        => $enable_api_v2,
  }

  firewall { '207 zaqar-api' :
    dport   => '8888',
    proto   => 'tcp',
    action  => 'accept',
  }

}
