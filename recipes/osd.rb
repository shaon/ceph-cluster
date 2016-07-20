#
# Cookbook Name:: ceph-cluster
# Recipe:: default
#
# Copyright 2016
#

include_recipe "ceph-cluster::default"

if node[:platform].include?("redhat")
  yum_package "ceph-osd" do
    action :install
    version node['version']
  end
end

mons = node['ceph']['topology']['mons']
if mons != nil
  gather_mons(node, mons)
end

ceph_conf = "/etc/ceph/ceph.conf"
client_admin_keyring = '/etc/ceph/ceph.client.admin.keyring'

template "#{ceph_conf}" do
  source 'ceph.conf.erb'
  action :create
  notifies :restart, 'service[ceph]', :immediately
  notifies :run, 'ruby_block[save config_data]', :delayed
end

template "#{client_admin_keyring}" do
  source 'ceph.client.admin.keyring.erb'
  action :create
  only_if { admin_secret }
end

cluster = 'ceph'

execute 'format bootstrap-osd as keyring' do
  command lazy { "ceph-authtool '/var/lib/ceph/bootstrap-osd/#{cluster}.keyring' --create-keyring --name=client.bootstrap-osd --add-key='#{osd_secret}'" }
  creates "/var/lib/ceph/bootstrap-osd/#{cluster}.keyring"
  only_if { osd_secret }
end


# adding drive for osd
osds = node['ceph']['topology']['osds']
this_osd = nil
osd_journal_path = node['ceph']['system-properties']['journal-path']

if osds != nil

  osds.each do |osd|
    if osd['hostname'] == node['hostname']
      this_osd = osd
      break
    end
  end

  # unless this_osd['journal-path']
  #   this_osd['journal-path'] = nil
  # end

  if this_osd['drives']

    this_osd['drives'].each do |osd_drive|
      unless osd_drive['disk']['status']
        node.set['ceph']['osd_drives']["#{osd_drive['disk']}"]['status'] = 'premordial'
        node.save
      end

      if node['ceph']['osd_drives']["#{osd_drive['disk']}"]['status'] != 'deployed'
        ceph_cluster_builder "add osd drives" do
          component "osd"
          osd_type "drive"
          journal_path this_osd['journal-path']
          drive osd_drive['disk']
          action :add
          notifies :create, "ruby_block[save osd status #{osd_drive['disk']}]", :immediately
        end
      end

      ruby_block "save osd status #{osd_drive['disk']}" do
        block do
          node.set['ceph']['osd_drives']["#{osd_drive['disk']}"]['status'] = "deployed"
          node.save
        end
        action :nothing
      end

    end
  else
    ceph_cluster_builder "add osd" do
      component "osd"
      osd_type "osdrive"
      action :add
      only_if { osd_allowed }
    end
  end

end # osd != nil


ruby_block 'save config_data' do
  block do
    save_data_from_file(node, ceph_conf, "config_data")
  end
  action :nothing
end

service "ceph" do
  provider Chef::Provider::Service::Redhat
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
