#
# Cookbook Name:: ceph-cluster
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
#
include_recipe "ntp::default"

yum_package "ceph" do
  action :upgrade
  flush_cache [:before]
end

yum_package "ceph-radosgw" do
  action :upgrade
  flush_cache [:before]
end

yum_package "xfsprogs" do
  action :upgrade
  flush_cache [:before]
end

execute "update-ntpdate" do
  command "ntpdate -u #{node['ceph']['ntp_server']}"
end
