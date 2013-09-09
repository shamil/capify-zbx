require File.join(File.dirname(__FILE__), '../capify-zbx')
require 'colored'

Capistrano::Configuration.instance(:must_exist).load do
  namespace :zabbix do
    desc "Prints out all zabbix hosts. index, hostname, hostid, role"
    task :status do
      roles = fetch(:zbx_roles, nil)
      roles = roles.split(/\s*,\s*/) if roles
      hosts = CapifyZbx.available_hosts

      # show only specific roles if asked
      if (roles)
        hosts = []
        roles.uniq.each { |role| hosts += CapifyZbx.get_hosts_by_role(role) }
      end

      hosts.each_with_index do |host, i|
        puts sprintf "%-12s:  %-32s id=%-20s role='%s'",
          i.to_s.white, host['name'], host['hostid'].red, host['capistrano_role'].yellow
      end
    end

    desc "Allows ssh to server by choosing from list of running hosts"
    task :ssh do
      roles = fetch(:zbx_roles, nil)
      roles = roles.split(/\s*,\s*/) if roles
      hosts = CapifyZbx.available_hosts

      # show only specific roles if asked
      if (roles)
        hosts = []
        roles.uniq.each { |role| hosts += CapifyZbx.get_hosts_by_role(role) }
      end

      # show asked servers and let user choose
      status

      # wait for input
      begin
        server = Capistrano::CLI.ui.ask("Enter # [0]: ").to_i
      rescue Interrupt
        puts
        Kernel.exit
      end

      host = hosts[server.to_i]
      port = ssh_options[:port] || 22
      login = fetch(:user)
      command = "ssh -p #{port} -l #{login} #{host['name']}"
      puts "Running `#{command}`"
      exec(command)
    end
  end

  def zbx_roles(*roles)
    roles.each {|role| zbx_role(role)}
  end

  def zbx_role(role_name_or_hash)
    role = role_name_or_hash.is_a?(Hash) ? role_name_or_hash : {:name => role_name_or_hash, :options => {}}


    # get instances by ec2 role tags
    hosts = CapifyZbx.get_hosts_by_role(role[:name].to_s)

    # add 'default' roles, as static
    if role[:options].delete(:default)
      hosts.each do |host|
        define_role_static(role, host)
      end
    end

    define_role_roles(role, hosts) # generates role for group of hosts
    #define_host_roles(role, hosts) # generates role for each host (role per host)
  end

  def define_role_roles(role, hosts)
    task role[:name].to_sym do
      remove_default_roles
      hosts.each do |host|
        define_role(role, host)
      end
    end
  end

  def define_host_roles(role, hosts)
    hosts.each do |host|
      task host['name'].to_sym do
        remove_default_roles
        define_role(role, host)
      end
    end
  end

  # creates a role (dynamic)
  def define_role(role, host)
    options = role[:options]
    new_options = {}
    options.each {|key, value| new_options[key] = true if value.to_s == host['name']}

    if new_options
      role(role[:name].to_sym, new_options) { host['name'] }
    else
      role(role[:name].to_sym) { host['name'] }
    end
  end

  # creates a role (static)
  def define_role_static(role, host)
    options = role[:options]
    new_options = {}
    options.each {|key, value| new_options[key] = true if value.to_s == host['name']}

    if new_options
      role role[:name].to_sym, host['name'], new_options
    else
      role role[:name].to_sym, host['name']
    end
  end

  def numeric?(object)
    true if Float(object) rescue false
  end

  # delete 'static' roles
  def remove_default_roles
    roles.each {|role| role[1].instance_variable_set(:@static_servers, []) }
  end

end
