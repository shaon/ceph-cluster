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

osds = node['ceph']['topology']['osds']

osds.each do |osd|

  if osd['hostname'] == node['hostname']
    if osd['journal-path']
      execute "remove-all-ceph-artifacts" do
        command "parted -s -a optimal #{osd['journal-path']} mklabel msdos"
        ignore_failure true
      end
    end

    if osd['drives']
      osd['drives'].each do |osd_drive|
        execute "remove-all-ceph-artifacts" do
          command "umount #{osd_drive['disk']}1"
          ignore_failure true
        end
        execute "remove-all-ceph-artifacts" do
          command "ceph-disk zap #{osd_drive['disk']}"
          ignore_failure true
        end
        execute "remove-all-ceph-artifacts" do
          command "parted -s -a optimal #{osd_drive['disk']} mklabel msdos"
          ignore_failure true
        end
      end
    end

    break
  end

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
