#
# Cookbook Name:: ceph-cluster
# Recipe:: default
#
# Copyright 2016
#

def execute_command(cmd)
  Chef::Log.info "executing: #{cmd}"
  result = Mixlib::ShellOut.new(cmd).run_command.stdout.strip
  return result
end

def gather_mons(node, mons)
  mons.each do |value|
    if value['init'] == true
      node.default['ceph']['config']['initial_members'] << value['hostname']
      node.default['ceph']['config']['initial_host'] << value['ipaddr']
    else
      node.default['ceph']['config']['mons'] = node['ceph']['config']['mons'].merge({value['hostname'] => value['ipaddr']})
    end
    node.save
  end
end

def mon_secret
  mons = node['ceph']['topology']['mons']
  mon_secret = nil
  mons.each do |value|
    found = Chef::Search::Query.new.search(:node, "addresses:#{value['ipaddr']}").first.first
    if found.attributes['ceph']['monitor-secret']
      mon_secret = found.attributes['ceph']['monitor-secret']
      break
    end
  end
  mon_secret
end

def osd_secret
  mons = node['ceph']['topology']['mons']
  osd_secret = nil
  mons.each do |value|
    found = Chef::Search::Query.new.search(:node, "addresses:#{value['ipaddr']}").first.first
    if found.attributes['ceph']['osd-bootstrap-key']
      osd_secret = found.attributes['ceph']['osd-bootstrap-key']
      break
    end
  end
  if osd_secret == ""
    return nil
  else
    return osd_secret
  end
end

def admin_secret
  mons = node['ceph']['topology']['mons']
  admin_key = nil
  mons.each do |mon|
    found = Chef::Search::Query.new.search(:node, "addresses:#{mon['ipaddr']}").first.first
    if found.attributes['ceph']['client-admin-key']
      admin_key = found.attributes['ceph']['client-admin-key']
      node.set['ceph']['client-admin-key'] = admin_key
      node.save
      break
    end
  end
  admin_key
end

def get_keyring(keyname, filepath)
  cmd = Mixlib::ShellOut::new("ceph-authtool #{filepath} --print-key --name='#{keyname}'")
  cmd.run_command
  {
    :result => cmd.stdout =~ /==/,
    :keyring => cmd.stdout.strip,
    :has_key => cmd.stderr !~ /entity #{keyname} not found/
  }
end

def has_keyring(keyname, filepath)
  kr = get_keyring(keyname, filepath)
  return kr[:has_key]
end

def osd_allowed
  osd_status = node['ceph']['status']
  Chef::Log.info "#{osd_status}"
  if osd_status == [] || osd_status[0]['deployed'] == false
    true
  else
    false
  end
end

def get_drive_status(drive)
  cmd = Mixlib::ShellOut.new("ceph-disk list | grep #{drive}")
  cmd.run_command
  {
    :is_drive => cmd.stdout =~ /#{drive}/,
    :output => cmd.stdout.strip || cmd.stderr.strip,
    :is_mounted => cmd.stdout !~ /mounted/
  }
end

def osd_drive_allowed(drive)
  osd_status = node['ceph']['status']
  Chef::Log.info "#{osd_status}"
  status = get_drive_status(drive)
  Chef::Log.info "status[:is_drive]: #{status[:is_drive]}, status[:is_mounted]: #{status[:is_mounted]}"

  status[:is_drive] && status[:is_mounted]
end

def get_user(username)
  cmd = Mixlib::ShellOut::new("ceph auth get client.#{username}")
  cmd.run_command
  {
    :output => cmd.stdout,
    :status => cmd.stderr !~ /Error ENOENT: failed to find client.#{username} in keyring/
  }
end

def user_exists(username)
  user = get_user(username)
  Chef::Log.info "#{user}"
  return user[:status]
end

def save_data_from_file(node, filename, attribute)
  Chef::Log.info "Saving #{filename} to #{attribute}"
  if File.exists?("#{filename}")
    conf_data = Base64.encode64(::File.new("#{filename}").read)
    node.set['ceph'][attribute] = conf_data
    node.save
  end
end

def write_data_to_file(node, filename, attribute)
  mons = node['ceph']['topology']['mons']
  environment = node.chef_environment
  data = nil
  mons.each do |mon|
    Chef::Log.info "trying: #{mon}"
    found = Chef::Search::Query.new.search(:node, "addresses:#{mon['ipaddr']}").first.first
    if found.attributes['ceph'][attribute]
      Chef::Log.info "found: #{found}"
      data = found.attributes['ceph'][attribute]
      break
    end
  end
  File.open(filename, 'w') do |file|
    file.puts Base64.decode64(data)
  end
end

def download_user_keyring(node, username)
  mons = node['ceph']['topology']['mons']
  environment = node.chef_environment
  file_name = "/root/ceph.client.#{username}.keyring"
  keyring_data = nil
  mons.each do |mon|
    Chef::Log.info "trying: #{mon}"
    found = Chef::Search::Query.new.search(:node, "addresses:#{mon['ipaddr']}").first.first
    if found != nil
      Chef::Log.info "found: #{found}"
      keyring_data = found.attributes['ceph']['keyring_data'][username]
      break
    end
  end
  File.open(file_name, 'w') do |file|
    file.puts Base64.decode64(keyring_data)
  end
end
