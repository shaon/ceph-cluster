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

    CephCluster::DataHelper.retrieve_keyring_data(node)

    CephCluster::DataHelper.retrieve_config_data(node)
  end
end

ruby_block "Get-OSD-Num" do
  block do
    osd_num = Mixlib::ShellOut.new("ceph osd create").run_command.stdout.strip
    node.run_state['ceph_osd_num'] = osd_num

    Mixlib::ShellOut.new("mkdir /dev/osd#{osd_num}").run_command.stdout.strip
    Mixlib::ShellOut.new("mkdir /var/lib/ceph/osd/ceph-#{osd_num}").run_command.stdout.strip
    Mixlib::ShellOut.new("ceph-osd -i #{osd_num} --mkfs --mkkey").run_command.stdout.strip
    Mixlib::ShellOut.new("ceph auth add osd.#{osd_num} osd 'allow *' mon 'allow rwx' -i /var/lib/ceph/osd/ceph-#{osd_num}/keyring").run_command.stdout.strip
    Mixlib::ShellOut.new("touch /var/lib/ceph/osd/ceph-#{osd_num}/sysvinit").run_command.stdout.strip
  end
  only_if { ::File.exists?("/etc/ceph/ceph.conf") }
end

ruby_block "Print-OSD-Num" do
  block do
    Chef::Log.info "Print-OSD-Num: #{node.run_state['ceph_osd_num']}"
  end
end

service "ceph" do
  provider Chef::Provider::Service::Redhat
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
