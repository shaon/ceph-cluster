#
# Cookbook Name:: ceph-cluster
# Recipe:: default
#
# Copyright 2016
#

users = node['ceph']['users']

if users != nil
  users.each do |user|

    if user['pool']
      ceph_cluster_user "add user #{user['name']}" do
        username user['name']
        poolname user['pool']
        action :add
        not_if { user_exists(username) }
      end
    else
      ceph_cluster_user "add user #{user['name']}" do
        username user['name']
        action :add
        not_if { user_exists(username) }
      end
    end

    ruby_block "print-save keyring #{user['name']}" do
      block do
        result = get_user(user['name'])
        Chef::Log.info "#{result[:output]}"
        node.set['ceph']['keyring_data'][user['name']] = Base64.encode64(result[:output])
        node.save
      end
    end

  end
end
