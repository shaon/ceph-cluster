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

osd_num = 1

ruby_block "Get-Init-Mons" do
  block do
    node.set['ceph']['config']['topology']['mons']['hostnames'] = mon_hostnames
    node.save

    node.set['ceph']['config']['topology']['mons']['ipaddrs'] = mon_ipaddrs
    node.save
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
    osds = node['ceph']['topology']['osds']
    if osds != nil
      osds.each do |osd|
        if osd['hostname'] == node['hostname'] # hostname comparison
          Chef::Log.info "looping: #{osd}"
          drives = osd['drive']
          if drives != nil
            drives.each do |drive|
              mount_point = ""
              mount_point = Mixlib::ShellOut.new("mount | grep #{drive}").run_command.stdout.strip
              if File.exists?("#{drive}") && mount_point !~ /ceph/
                Chef::Log.info "found osd drive: #{drive}. Will construct filesystem and mount."
		Mixlib::ShellOut.new("umount #{drive}").run_command.stdout.strip
                Mixlib::ShellOut.new("mkfs -t xfs -f #{drive}").run_command.stdout.strip
                Mixlib::ShellOut.new("mount #{drive} /var/lib/ceph/osd/").run_command.stdout.strip
                Mixlib::ShellOut.new("sed -i \"s[#{drive} *.* *defaults *1 *2[#{drive} /var/lib/ceph/osd/ xfs defaults 1 2[\" /etc/fstab").run_command.stdout.strip
              else
                Chef::Log.info "#{drive} is mounted or does not exist anymore. Keep calm and call Batman."
              end
            end
          end # drives != nil
              osd_id = Mixlib::ShellOut.new("ceph osd create").run_command.stdout.strip
              Mixlib::ShellOut.new("mkdir /var/lib/ceph/osd/ceph-#{osd_id}").run_command.stdout.strip
              CephCluster::DataHelper.add_osd(node, osd_id)
        end # hostname comparison
      end # osds.each
    end # osds != nil
  end
  only_if { ::File.exists?("/etc/ceph/ceph.conf") }
  notifies :reload, 'service[ceph]', :immediately
end

service "ceph" do
  provider Chef::Provider::Service::Redhat
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
