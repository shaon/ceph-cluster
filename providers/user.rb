#
# Cookbook Name:: ceph-cluster
# Recipe:: default
#
# Copyright 2016
#

def add_user(node, username, poolname)
  n = "client.#{username}"

  if poolname == nil
    Mixlib::ShellOut.new("ceph auth add #{n} mon 'allow r' osd 'allow rwx'").run_command.stdout
  else
    Mixlib::ShellOut.new("ceph auth add #{n} mon 'allow r' osd 'allow rwx pool=#{poolname}'").run_command.stdout
  end
  Mixlib::ShellOut.new("ceph auth get #{n} -o /etc/ceph/ceph.#{n}.keyring").run_command.stdout
end

action :add do
  add_user(node, new_resource.username, new_resource.poolname)
  new_resource.updated_by_last_action(true)
end

action :delele do
  username = new_resource.username
  Mixlib::ShellOut.new("ceph auth del client.#{username}").run_command.stdout
end
