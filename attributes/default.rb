# default['ceph']['config']['fsid'] = nil
default['ceph']['config']['bind-interface'] = 'eth0'

default['ceph']['config']['initial_members'] = []
default['ceph']['config']['initial_host'] = []

default['ceph']['config']['mons'] = {}
default['ceph']['users'] = {}

default['ceph']['config']['mon_port'] = 6789
default["ceph"]["config"]["auth_cluster_required"] = "cephx"
default["ceph"]["config"]["auth_service_required"] = "cephx"
default["ceph"]["config"]["auth_client_required"] = "cephx"
default["ceph"]["config"]["filestore_xattr_use_omap"] = true
default["ceph"]["config"]["osd_pool_default_pg_num"] = 128
default["ceph"]["config"]["osd_pool_default_pgp_num"] = 128
default["ceph"]["config"]["osd_pool_default_size"] = 2

default['ceph']['ntp_server'] = "pool.ntp.org"

default["ceph"]['config']['topology']['osds']['hostnames'] = []

default['ceph']['status'] = []
