module Puppet::Parser::Functions
  newfunction(:get_user_id_by_name, :type => :rvalue,
:doc => <<-EOS
Returns the user id from domain name and user name.
EOS
  ) do |arguments|

    require File.expand_path(File.join(
                    File.dirname(__FILE__), '..', '..', '..',
                    'puppet', 'util', 'cmd'))

    raise(Puppet::ParseError, 'Argument order should be os_token, os_identity_api_version, os_url, user_name, domain_name') if arguments.size > 5

    os_token                  = arguments[0]
    os_identity_api_version   = arguments[1] || '3'
    os_url                    = arguments[2]
    user_name                 = arguments[3]
    domain_name               = arguments[4]

    user_id_query = %(openstack --os-token "#{os_token}" --os-identity-api-version "#{os_identity_api_version}" --os-url "#{os_url}" user show "#{user_name}" --domain "#{domain_name}" | awk '/ id /{print $4}')

    user_id = Puppet::Util::Cmd.run_command(user_id_query)

    return user_id

  end
end

# vim: set ts=2 sw=2 et :
