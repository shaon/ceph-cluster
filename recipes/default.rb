#
# Cookbook Name:: ceph-cluster
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
#

yum_package "ceph" do
  action :upgrade
  flush_cache [:before]
end

yum_package "ceph-radosgw" do
  action :upgrade
  flush_cache [:before]
end
