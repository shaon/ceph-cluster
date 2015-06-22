service "ceph" do
  action :stop
  ignore_failure true
  only_if do ::File.exists?('/etc/init.d/ceph') end
end

yum_package "ceph" do
  action :remove
  ignore_failure true
end

yum_package "ceph-radosgw" do
  action :remove
  ignore_failure true
end

yum_package "xfsprogs" do
  action :remove
  ignore_failure true
end

execute "remove-all-ceph-packages" do
  command "for x in `rpm -qa | grep ceph`; do rpm -e $x; done"
  ignore_failure true
end

execute "remove-all-ceph-artifacts" do
  command "for x in `find / -name 'ceph'`; do rm -rf $x; done"
  ignore_failure true
end

execute "remove-all-monmap" do
  command "rm -rf /tmp/ceph.mon.keyring /tmp/monmap"
  ignore_failure true
end
