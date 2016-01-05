#
# Cookbook Name:: ceph-cluster
# Recipe:: default
#
# Copyright 2016
#

service "ceph" do
  action :stop
  ignore_failure true
  only_if do ::File.exists?('/etc/init.d/ceph') end
end

%w{ceph ceph-radosgw xfsprogs ceph-common python-ceph libcephfs1}.each do |pkg|
  package pkg do
    action :remove
    ignore_failure true
  end
end

execute "remove-all-ceph-artifacts" do
  command "rm -rf /usr/share/ceph /var/lib/ceph"
  ignore_failure true
end

execute "remove-all-monmap" do
  command "rm -rf /tmp/ceph.mon.keyring /tmp/monmap"
  ignore_failure true
end
