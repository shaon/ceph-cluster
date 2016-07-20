#
# Cookbook Name:: ceph-cluster
# Recipe:: default
#
# Copyright 2016
#

include_recipe "ceph-cluster::default"


if node[:platform].include?("redhat")
  yum_package "ceph-mon" do
    action :install
    version node['version']
  end
end

mons = node['ceph']['topology']['mons']
if mons != nil
  gather_mons(node, mons)
end

ceph_conf = "/etc/ceph/ceph.conf"
keyring = '/tmp/ceph.mon.keyring'
client_admin_keyring = '/etc/ceph/ceph.client.admin.keyring'

template "#{ceph_conf}" do
  source 'ceph.conf.erb'
  action :create
  # notifies :restart, 'service[ceph]', :immediately
  notifies :run, 'ruby_block[save config_data]', :delayed
end

execute 'format mon-secret as keyring' do
  command lazy { "ceph-authtool --create-keyring '#{keyring}' --name=mon. --add-key='#{mon_secret}' --cap mon 'allow *'" }
  creates keyring
  only_if { mon_secret }
end

template "#{client_admin_keyring}" do
  source 'ceph.client.admin.keyring.erb'
  action :create
  only_if { admin_secret }
end

execute "Create Mon keyring" do
  command "ceph-authtool --create-keyring #{keyring} --gen-key -n mon. --cap mon 'allow *'"
  creates keyring
  not_if { mon_secret }
  notifies :create, 'ruby_block[save mon_secret]', :delayed
end

ruby_block "save mon_secret" do
  block do
    fetch = Mixlib::ShellOut.new("ceph-authtool '#{keyring}' --print-key --name=mon.")
    fetch.run_command
    key = fetch.stdout
    node.set['ceph']['monitor-secret'] = key
    node.save
  end
  action :nothing
end

execute 'create client-admin-keyring' do
  command "ceph-authtool --create-keyring #{client_admin_keyring} --gen-key -n client.admin --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow'"
  creates client_admin_keyring
  not_if do ::File.exists?("#{client_admin_keyring}") end
end

execute 'import client-admin-keyring' do
  command "ceph-authtool #{keyring} --import-keyring #{client_admin_keyring}"
  not_if { has_keyring("client.admin", "#{keyring}") }
  notifies :run, 'ruby_block[save client-admin-keyring]', :delayed
end

ruby_block 'save client-admin-keyring' do
  block do
    client_admin_key = get_keyring("client.admin", "#{keyring}")
    node.set['ceph']['client-admin-key'] = client_admin_key[:keyring]
    node.save
  end
  only_if { has_keyring("client.admin", "#{keyring}") }
  action :nothing
end

ceph_dir = "/var/lib/ceph/mon/ceph-#{node['hostname']}"

execute 'ceph-mon mkfs' do
  command "ceph-mon --mkfs -i #{node['hostname']} --keyring #{keyring} --mon-host #{node['ceph']['config']['initial_host'].join(',')}"
  creates ceph_dir
  notifies :create, "file[#{ceph_dir}/done]", :immediately
  notifies :create, "file[#{ceph_dir}/sysvinit]", :immediately
  notifies :run, "ruby_block[save osd bootstrap-keyring]", :delayed
end

file "#{ceph_dir}/done" do
  action :create
end

file "#{ceph_dir}/sysvinit" do
  action :create
end

ruby_block 'save config_data' do
  block do
    save_data_from_file(node, ceph_conf, "config_data")
  end
  action :nothing
end

ruby_block 'save osd bootstrap-keyring' do
  block do
    fetch = Mixlib::ShellOut.new('ceph auth get-key client.bootstrap-osd')
    fetch.run_command
    key = fetch.stdout
    node.set['ceph']['osd-bootstrap-key'] = key
    node.save
  end
  not_if { osd_secret }
  # action :nothing
end

service "ceph" do
  provider Chef::Provider::Service::Redhat
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
