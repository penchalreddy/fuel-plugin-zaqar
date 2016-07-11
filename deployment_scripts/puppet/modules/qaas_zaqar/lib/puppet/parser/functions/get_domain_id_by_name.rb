module Puppet::Parser::Functions
  newfunction(:get_domain_id_by_name, :type => :rvalue,
:doc => <<-EOS
Returns the domain id from domain name
EOS
  ) do |arguments|

    require File.expand_path(File.join(
                    File.dirname(__FILE__), '..', '..', '..',
                    'puppet', 'util', 'cmd'))

    raise(Puppet::ParseError, 'Argument order should be os_token, os_identity_api_version, os_url, domain_name') if arguments.size > 4

    os_token                  = arguments[0]
    os_identity_api_version   = arguments[1] || '3'
    os_url                    = arguments[2]
    domain_name               = arguments[3]

    domain_id_query = %(openstack --os-token "#{os_token}" --os-identity-api-version "#{os_identity_api_version}" --os-url "#{os_url}" domain show "#{domain_name}" | awk '/ id /{print $4}')

    domain_id = Puppet::Util::Cmd.run_command(domain_id_query)

    return domain_id

  end
end

# vim: set ts=2 sw=2 et :
