#
# Cookbook Name:: ceph-cluster
# Recipe:: default
#
# Copyright 2016
#

include_recipe "ntp::default"

%w{ceph ceph-radosgw xfsprogs hdparm parted}.each do |pkg|
  yum_package pkg do
    action :upgrade
    flush_cache [:before]
  end
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
