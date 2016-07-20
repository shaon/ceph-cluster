# default['ceph']['config']['fsid'] = nil
default['ceph']['config']['bind-interface'] = 'eth0'

default['ceph']['config']['initial_members'] = []
default['ceph']['config']['initial_host'] = []

default['ceph']['config']['mons'] = {}
default['ceph']['users'] = {}

# Repository
default['ceph']['baseurl'] = "http://download.ceph.com/rpm-hammer/el7/x86_64/"
default['ceph']['version'] = "0.94.6-0.el7"

default['ceph']['config']['mon_port'] = 6789
default["ceph"]["config"]["auth_cluster_required"] = "cephx"
default["ceph"]["config"]["auth_service_required"] = "cephx"
default["ceph"]["config"]["auth_client_required"] = "cephx"
default["ceph"]["config"]["filestore_xattr_use_omap"] = true
default["ceph"]["config"]["osd-pool-default-pg-num"] = 128
default["ceph"]["config"]["osd-pool-default-pgp-num"] = 128
default["ceph"]["config"]["osd-pool-default-size"] = 3
default["ceph"]["config"]["osd-pool-default-min-size"] = 1
default["ceph"]["config"]["osd-journal-size"] = 5120

default["ceph"]["system-properties"]["journal-path"] = nil

default['ceph']['ntp_server'] = "pool.ntp.org"

default["ceph"]['config']['topology']['osds']['hostnames'] = []

default['ceph']['status'] = []
