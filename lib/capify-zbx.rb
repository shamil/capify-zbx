require 'rubygems'
require 'zabbixapi'
require 'yaml'

class CapifyZbx
    @hosts = []

    # get config
    def self.zbx_config
        YAML::load_file('config/zabbix.yml')
    end

    # get hosts from zabbix
    def self.available_hosts()
        # no need to go over the process of getting the hosts if we did it already
        return @hosts if (@hosts.count > 0)

        # Connect to Zabbix API
        zbx = ZabbixApi.connect(
            :url      => zbx_config[:url],
            :user     => zbx_config[:user],
            :password => zbx_config[:password]
        )

        zbx.client.api_request(
            :method => 'hostgroup.get',
            :params => { :monitored_hosts => true, :selectHosts => "extend", :output => "extend" }).each do |hostgroup|

            # do not process ecluded host groups
            next if zbx_config[:exclude_hostgroups].include?(hostgroup["name"])

            hostgroup["hosts"].each do |host|
                if host["available"].to_i == 1 && host["maintenance_status"].to_i == 0
                    host['capistrano_role'] = hostgroup["name"]
                    @hosts << host
                end
            end
        end

        return @hosts
    end

    def self.get_hosts_by_role(name)
        available_hosts.select { |h| h['capistrano_role'].to_s == name }
    end

    def self.get_host_by_name(name)
        available_hosts.select { |h| h['name'].to_s == name }
    end
end # of CapifyZbx class
