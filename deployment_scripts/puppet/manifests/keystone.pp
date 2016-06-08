notice('MODULAR: keystone/keystone.pp')

$keystone_hash             = hiera_hash('fuel-plugin-keystone', {})
$public_ip                  = hiera('public_vip')
$management_ip              = hiera('management_vip')
$public_ssl                 = hiera('public_ssl')
$region                     = hiera('region', 'RegionOne')


$public_protocol = $public_ssl['services'] ? {
  true    => 'https',
  default => 'http',
}

$public_address = $public_ssl['services'] ? {
  true    => $public_ssl['hostname'],
  default => $public_ip,
}

$api_bind_port  = '8888'

$tenant         = pick($keystone_hash['metadata']['tenant'], 'services')
$public_url     = "${public_protocol}://${public_address}:${api_bind_port}"
$admin_url      = "http://${management_ip}:${api_bind_port}"

#################################################################

class { 'keystone::keystone::auth':
  password     => $keystone_hash['metadata']['user_password'],
  service_type => 'zaqar',
  region       => $region,
  tenant       => $tenant,
  public_url   => $public_url,
  admin_url    => $admin_url,
  internal_url => $admin_url,
}
