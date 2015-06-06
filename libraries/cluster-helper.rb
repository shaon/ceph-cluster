module CephCluster
  module DataHelper


    def self.save_config_data(node)
      Chef::Log.info "Saving ceph.conf data"
      if File.exists?("/etc/ceph/ceph.conf")
        conf_data = Base64.encode64(::File.new("/etc/ceph/ceph.conf").read)
        node.set['ceph']['config']['conf_data'] = conf_data
        node.save
      end
    end

    def self.retrieve_config_data(node)
      mon_bootstrap = node['ceph']['topology']['mon_bootstrap']['ipaddr']
      environment = node.chef_environment
      file_name = "/etc/ceph/ceph.conf"
      Chef::Log.info "Getting all attributes from #{mon_bootstrap}"
      bootstrap_node = Chef::Search::Query.new.search(:node, "addresses:#{mon_bootstrap}").first.first
      config_data = bootstrap_node.attributes['ceph']['config']['conf_data']
      File.open(file_name, 'w') do |file|
        file.puts Base64.decode64(config_data)
      end
    end

    def self.save_keyring_temp(node)
      Chef::Log.info "Saving keyring data"
      if File.exists?("/tmp/ceph.mon.keyring")
        keyring_temp = Base64.encode64(::File.new("/tmp/ceph.mon.keyring").read)
        node.set['ceph']['config']['keyring_temp'] = keyring_temp
        node.save
      end
    end

    def self.retrieve_keyring_temp(node)
      mon_bootstrap = node['ceph']['topology']['mon_bootstrap']['ipaddr']
      environment = node.chef_environment
      file_name = "/tmp/ceph.mon.keyring"
      Chef::Log.info "Getting all attributes from #{mon_bootstrap}"
      bootstrap_node = Chef::Search::Query.new.search(:node, "addresses:#{mon_bootstrap}").first.first
      keyring_temp = bootstrap_node.attributes['ceph']['config']['keyring_temp']
      File.open(file_name, 'w') do |file|
        file.puts Base64.decode64(keyring_temp)
      end
    end

    def self.save_keyring_data(node)
      Chef::Log.info "Saving keyring data"
      if File.exists?("/etc/ceph/ceph.client.admin.keyring")
        keyring_data = Base64.encode64(::File.new("/etc/ceph/ceph.client.admin.keyring").read)
        node.set['ceph']['config']['keyring_data'] = keyring_data
        node.save
      end
    end

    def self.retrieve_keyring_data(node)
      mon_bootstrap = node['ceph']['topology']['mon_bootstrap']['ipaddr']
      environment = node.chef_environment
      file_name = "/etc/ceph/ceph.client.admin.keyring"
      Chef::Log.info "Getting all attributes from #{mon_bootstrap}"
      bootstrap_node = Chef::Search::Query.new.search(:node, "addresses:#{mon_bootstrap}").first.first
      keyring_data = bootstrap_node.attributes['ceph']['config']['keyring_data']
      File.open(file_name, 'w') do |file|
        file.puts Base64.decode64(keyring_data)
      end
    end

  end
end
