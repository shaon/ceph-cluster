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

template '/etc/ceph/ceph.conf' do
  source 'ceph.conf.erb'
end

execute 'generate mon-secret as keyring' do
  command "ceph-authtool /tmp/ceph.mon.keyring --create-keyring --gen-key --name=mon."
  not_if { ::File.exists?("/tmp/ceph.mon.keyring")}
end

execute "Generate admin keyring, client.admin user & add the user to the keyring" do
  command "ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --set-uid=0 --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow'"
  not_if { ::File.exists?("/etc/ceph/ceph.client.admin.keyring")}
end

execute "Add the client.admin key to the ceph.mon.keyring" do
  command "ceph-authtool /tmp/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring"
  # not_if { ::File.exists?("/etc/ceph/ceph.client.admin.keyring")}
end

execute "Generate a monitor map" do
  command "monmaptool --create --add #{node['hostname']} #{node['ipaddress']} --fsid #{node['ceph']['config']['fsid']} /tmp/monmap --clobber"
  not_if { ::File.exists?("/tmp/monmap")}
end

execute "Populate the monitor daemon" do
  command "ceph-mon --mkfs -i #{node['hostname']} --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring"
  not_if { ::File.exist?("/var/lib/ceph/mon/ceph-#{node['hostname']}") }
end

execute "Add-done" do
  command "touch /var/lib/ceph/mon/ceph-#{node['hostname']}/done"
  not_if { ::File.exist?("/var/lib/ceph/mon/ceph-#{node['hostname']}/done") }
end

execute "Add-sysvinit" do
  command "touch /var/lib/ceph/mon/ceph-#{node['hostname']}/sysvinit"
  not_if { ::File.exist?("/var/lib/ceph/mon/ceph-#{node['hostname']}/sysvinit") }
end

ruby_block "Save-Ceph-Keyring" do
  block do
    CephCluster::DataHelper.save_keyring_data(node)
  end
end

ruby_block "Save-Ceph-Temp-Keyring" do
  block do
    CephCluster::DataHelper.save_keyring_temp(node)
  end
end

ruby_block "Save-Ceph-Config" do
  block do
    CephCluster::DataHelper.save_config_data(node)
  end
end

service "ceph" do
  provider Chef::Provider::Service::Redhat
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
