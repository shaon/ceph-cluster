#
# Cookbook Name:: ceph-cluster
# Recipe:: default
#
# Copyright 2016
#

actions :add, :delete
attribute :username, kind_of: String, required: true, default: nil
attribute :poolname, kind_of: String, default: nil
