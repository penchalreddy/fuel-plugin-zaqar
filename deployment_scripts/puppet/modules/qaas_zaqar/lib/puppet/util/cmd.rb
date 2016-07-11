require 'open3'
require 'puppet'

module Puppet
  module Util
    class Cmd

      def self.run_command(command)
        Open3.popen3(command) do |stdin, stdout, stderr|
          begin
            puts "Executing openstack request:#{command}"
            stdout = stdout.read
            puts "Response from openstack request:#{stdout}"
            return stdout
          rescue Exception => e
            puts "Request failed, this sh*t is borked :( : details: #{e}"
            exit 1
          end
        end
      end

    end
  end
end
