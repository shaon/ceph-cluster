#
# Cookbook Name:: ceph-cluster
# Recipe:: default
#
# Copyright 2016
#

actions :add, :remove
attribute :component, kind_of: String, required: true, default: nil
attribute :osd_type, kind_of: String, default: "osdrive"
attribute :fstype, kind_of: String, default: "xfs"
attribute :drive, kind_of: String, default: nil
attribute :journal_path, kind_of: String, default: nil
