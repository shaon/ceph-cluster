#
# Cookbook Name:: ceph-cluster
# Recipe:: default
#
# Copyright 2016
#

def add_basic_osd(node, osd_id, drive)

  Chef::Log.debug "executing: ceph-osd -i #{osd_id} --mkfs --mkkey"
  Mixlib::ShellOut.new("ceph-osd -i #{osd_id} --mkfs --mkkey").run_command.stdout
  Chef::Log.debug "executing: ceph auth add osd.#{osd_id} osd 'allow *' mon 'allow rwx' -i /var/lib/ceph/osd/ceph-#{osd_id}/keyring"
  Mixlib::ShellOut.new("ceph auth add osd.#{osd_id} osd 'allow *' mon 'allow rwx' -i /var/lib/ceph/osd/ceph-#{osd_id}/keyring").run_command.stdout
  Chef::Log.debug "executing: touch /var/lib/ceph/osd/ceph-#{osd_id}/sysvinit"
  Mixlib::ShellOut.new("touch /var/lib/ceph/osd/ceph-#{osd_id}/sysvinit").run_command.stdout

  node.default['ceph']['status'] << {'component' => 'osd', 'deployed' => true, 'id' => osd_id, 'drive' => drive }
  node.save
end

def add_drive_for_osd(node, osd_id, fstype, drive)
  # we probably should not umount on any disk, :debatable
  # Mixlib::ShellOut.new("umount #{drive}").run_command.stdout.strip
  Mixlib::ShellOut.new("mkfs -t #{fstype} -f #{drive}").run_command.stdout.strip
  Mixlib::ShellOut.new("mount #{drive} /var/lib/ceph/osd/ceph-#{osd_id}").run_command.stdout.strip
  Mixlib::ShellOut.new("sed -i \"s[#{drive} *.* *defaults *1 *2[#{drive} /var/lib/ceph/osd/ xfs defaults 1 2[\" /etc/fstab").run_command.stdout.strip

end

action :add do
  if new_resource.component == "osd"
    Chef::Log.debug "executing: ceph osd create"
    osd_id = Mixlib::ShellOut.new("ceph osd create").run_command.stdout.strip
    Chef::Log.debug "executing: mkdir /var/lib/ceph/osd/ceph-#{osd_id}"
    Mixlib::ShellOut.new("mkdir /var/lib/ceph/osd/ceph-#{osd_id}").run_command.stdout

    if new_resource.osd_type == "drive"
      add_drive_for_osd(node, osd_id, new_resource.fstype, new_resource.drive)
    end
    add_basic_osd(node, osd_id, new_resource.drive)

  elsif new_resource.component == "mon"
    Chef::Log.info "TODO: Not implemented"
  end
  new_resource.updated_by_last_action(true)
end

action :remove do

end
