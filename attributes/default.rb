# default['ceph']['config']['fsid'] = nil

default['ceph']['config']['mon_initial_members'] = ""
default['ceph']['config']['mon_host'] = ""
default['ceph']['config']['mon_port'] = 6789
default["ceph"]["config"]["auth_cluster_required"] = "cephx"
default["ceph"]["config"]["auth_service_required"] = "cephx"
default["ceph"]["config"]["auth_client_required"] = "cephx"
default["ceph"]["config"]["filestore_xattr_use_omap"] = true
default["ceph"]["config"]["osd_pool_default_pg_num"] = 128
default["ceph"]["config"]["osd_pool_default_pgp_num"] = 128
default["ceph"]["config"]["osd_pool_default_size"] = 2

default['ceph']['keyring']['if_mon_secret'] = false

default['ceph']['config']['topology']['mons']['hostnames'] = []
default['ceph']['config']['topology']['mons']['ipaddrs'] = []

default["ceph"]['config']['topology']['osds']['hostnames'] = []
default['ceph']['osd']['num'] = nil
