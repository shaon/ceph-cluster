#
# Cookbook Name:: ceph-cluster
# Recipe:: default
#
# Copyright 2016
#

include_recipe "ntp::default"

yum_repository "ceph" do
  description "Ceph Repository"
  baseurl node['ceph']['baseurl']
  gpgcheck false
  action :create
end

%w{xfsprogs hdparm parted}.each do |pkg|
  yum_package pkg do
    action :install
    flush_cache [:before]
  end
end

yum_package "ceph" do
  version node['version']
  action :install
end

yum_package "ceph-radosgw" do
  version node['version']
  action :install
end

# temporary
yum_package "redhat-lsb-core" do
  action :upgrade
  flush_cache [:before]
end


execute "update-ntpdate" do
  command "ntpdate -u #{node['ceph']['ntp_server']}"
  action :run
end
