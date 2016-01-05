#
# Cookbook Name:: ceph-cluster
# Recipe:: default
#
# Copyright 2016
#

include_recipe "ceph-cluster::default"

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

# adding drive for osd
osds = node['ceph']['topology']['osds']
osd_drives = nil
osd_fstype = nil

if osds != nil
  osds.each do |osd|

    if osd['hostname'] == node['hostname'] && osd['drives']
      osd_drives = osd['drives']
      osd_fstype = osd['fstype']
      break
    end

  end
end

if osd_drives
  osd_drives.each do |osd_drive|
    ceph_cluster_builder "add osd" do
      component "osd"
      osd_type "drive"
      fstype osd_fstype
      drive osd_drive
      action :add
      notifies :run, 'ruby_block[save osd status]', :delayed
      only_if { osd_drive_allowed(osd_drive) }
    end
  end
else
  ceph_cluster_builder "add osd" do
    component "osd"
    osd_type "osdrive"
    action :add
    only_if { osd_allowed }
    notifies :run, 'ruby_block[save osd status]', :delayed
  end
end

ruby_block 'save osd status' do
  block do
    node.set['ceph']['status'] = node.default['ceph']['status']
    node.save
  end
  action :nothing
end

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
