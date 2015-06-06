#
# Cookbook Name:: ceph-cluster
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
#
include_recipe "ceph-cluster::default"

mon_hostnames = []
mon_ipaddrs = []
mons = node['ceph']['topology']['mons']
if mons != nil
  mons.each do |value|
    mon_hostnames << value['hostname']
    mon_ipaddrs << value['ipaddr']
  end
end

mon_hostnames << node['ceph']['topology']['mon_bootstrap']['hostname']
mon_ipaddrs << node['ceph']['topology']['mon_bootstrap']['ipaddr']

ruby_block "Get-Init-Mons" do
  block do
    node.set['ceph']['config']['topology']['mons']['hostnames'] = mon_hostnames
    node.save

    node.set['ceph']['config']['topology']['mons']['ipaddrs'] = mon_ipaddrs
    node.save
  end
end

ruby_block "Get-Init-Mons" do
  block do
    Chef::Log.info "#{mons}"
    Chef::Log.info "mon_initial_members: #{node['ceph']['config']['mon_initial_members']}"
    Chef::Log.info "#{node['ceph']['config']['topology']['mons']['hostnames'].join(",")}"
  end
end

ruby_block "retrieve-keyring-temp" do
  block do
    CephCluster::DataHelper.retrieve_keyring_temp(node)
  end
end

ruby_block "retrieve-keyring-data" do
  block do
    CephCluster::DataHelper.retrieve_keyring_data(node)
  end
end

ruby_block "retrieve-config-data" do
  block do
    CephCluster::DataHelper.retrieve_config_data(node)
  end
end

execute "monmap tool on node" do
  command "monmaptool --create --add #{node['hostname']} #{node['ipaddress']} --fsid #{node['ceph']['config']['fsid']} /tmp/monmap --clobber"
end

##
keyring = "/tmp/ceph.mon.keyring"
fsid = node['ceph']['config']['fsid']
c_mkfs = "ceph-mon --mkfs"

execute "mkfs-on-node" do
  command "#{c_mkfs} -i #{node['hostname']} --fsid #{fsid} --keyring #{keyring} --public-addr #{node['ipaddress']} --mon-host #{mon_hostnames.join(",")}"
  not_if { ::File.exist?("/var/lib/ceph/mon/ceph-#{node['hostname']}") }
end

execute "Mark that the monitor is created and ready to be started" do
  command "touch /var/lib/ceph/mon/ceph-#{node['hostname']}/done"
  not_if { ::File.exist?("/var/lib/ceph/mon/ceph-#{node['hostname']}/done") }
end

execute "Add sysvinit" do
  command "touch /var/lib/ceph/mon/ceph-#{node['hostname']}/sysvinit"
  not_if { ::File.exist?("/var/lib/ceph/mon/ceph-#{node['hostname']}/sysvinit") }
end

service "ceph" do
  provider Chef::Provider::Service::Redhat
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
