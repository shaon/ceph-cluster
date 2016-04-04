#
# Cookbook Name:: ceph-cluster
# Recipe:: default
#
# Copyright 2016
#

def run_cmd(cmd)
  Chef::Log.info "executing: #{cmd}"
  result = Mixlib::ShellOut.new(cmd).run_command.stdout.strip
  return result
end

def add_basic_osd(node, osd_id, drive)

  Chef::Log.info "executing: ceph-osd -i #{osd_id} --mkfs --mkkey"
  Mixlib::ShellOut.new("ceph-osd -i #{osd_id} --mkfs --mkkey").run_command.stdout
  Chef::Log.info "executing: ceph auth add osd.#{osd_id} osd 'allow *' mon 'allow rwx' -i /var/lib/ceph/osd/ceph-#{osd_id}/keyring"
  Mixlib::ShellOut.new("ceph auth add osd.#{osd_id} osd 'allow *' mon 'allow rwx' -i /var/lib/ceph/osd/ceph-#{osd_id}/keyring").run_command.stdout
  Chef::Log.info "executing: touch /var/lib/ceph/osd/ceph-#{osd_id}/sysvinit"
  Mixlib::ShellOut.new("touch /var/lib/ceph/osd/ceph-#{osd_id}/sysvinit").run_command.stdout

  node.default['ceph']['status'] << {'component' => 'osd', 'deployed' => true, 'id' => osd_id, 'drive' => drive }
  node.save
end

def add_drive_for_osd(node, fstype, drive, journal_path)
  if journal_path == nil
    run_cmd("ceph-disk prepare --cluster ceph --fs-type #{fstype} #{drive}")
  else
    run_cmd("ceph-disk prepare --cluster ceph --fs-type #{fstype} #{drive} #{journal_path}")
  end
  run_cmd("ceph-disk activate #{drive}1")
  # Mixlib::ShellOut.new("sed -i \"s[#{drive} *.* *defaults *1 *2[#{drive} /var/lib/ceph/osd/ xfs defaults 1 2[\" /etc/fstab").run_command.stdout.strip

end

def is_gpt_drive(drive)
  Chef::Log.info "executing: partprobe -d -s #{drive} | grep gpt"
  cmd = Mixlib::ShellOut::new("partprobe -d -s #{drive} | grep gpt")
  cmd.run_command
  {
    :result => cmd.stdout =~ /gpt partitions/,
    :output => cmd.stdout.strip,
    :has_partition => cmd.stderr !~ /1/
  }
end

action :add do
  if new_resource.component == "osd"

    if new_resource.osd_type == "drive"
      gpt_drive = is_gpt_drive(new_resource.drive)
      if gpt_drive[:result] == nil || gpt_drive[:has_partition]
        run_cmd("sgdisk --zap-all #{new_resource.drive}")
        run_cmd("sgdisk --mbrtogpt #{new_resource.drive}")
      end

      Chef::Log.info "running: add_drive_for_osd(node, new_resource.fstype, new_resource.drive, new_resource.journal_path)"
      add_drive_for_osd(node, new_resource.fstype, new_resource.drive, new_resource.journal_path)
    else
      Chef::Log.info "executing: ceph osd create"
      osd_id = Mixlib::ShellOut.new("ceph osd create").run_command.stdout.strip
      Chef::Log.info "executing: mkdir /var/lib/ceph/osd/ceph-#{osd_id}"
      Mixlib::ShellOut.new("mkdir /var/lib/ceph/osd/ceph-#{osd_id}").run_command.stdout
      add_basic_osd(node, osd_id, new_resource.drive)
    end

  elsif new_resource.component == "mon"
    Chef::Log.info "TODO: Not implemented"
  end
  new_resource.updated_by_last_action(true)
end

action :remove do

end
