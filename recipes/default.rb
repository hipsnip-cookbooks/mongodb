#
# Cookbook Name:: hipsnip-mongodb
# Recipe:: default
#
# Copyright 2013, HipSnip Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

raise "Running MongoDB on a 32bit box is a bad idea, so we won't let you do it - sorry!" if node['kernel']['machine'] == "i686"

chef_gem 'mongo' do
  version node['mongodb']['gem_version']['mongo']
end

require 'mongo'
require 'fileutils'

node.set['mongodb']['download']['src'] = "http://#{node['mongodb']['download']['host']}/#{node['mongodb']['download']['subfolder']}mongodb-linux-#{node['kernel']['machine']}-#{node['mongodb']['download']['version']}.tgz"

# Update TCP keepalive time
sysctl_param "net.ipv4.tcp_keepalive_time" do
  value node['mongodb']['tcp_keepalive_time']
  only_if { node['mongodb']['set_tcp_keepalive_time'] }
end


################################################################################
# Set up Mongo user, group and folders

group node['mongodb']['group'] do
  gid node['mongodb']['group_id']
  action :create
end

user node['mongodb']['user'] do
  gid   node['mongodb']['group_id']
  shell '/bin/false' # no login
  # no home dir
end

directory '/etc/mongodb' do
  mode  '755'
  owner 'root'
  group 'root'
end

if node['mongodb']['auth_enabled']
  if node['mongodb']['auth_keyfile'] == '/etc/mongodb/keyfile'
    raise '"auth_keyfile_data" can not be blank if authentication is enabled and no keyFile is specified' if node['mongodb']['auth_keyfile_data'].empty?

    # @NOTE: Changing the keyfile after there is an instance running
    #        means it will have to be restarted manually, otherwise
    #        the change will not take effect!
    file "/etc/mongodb/keyfile" do
      content node['mongodb']['auth_keyfile_data']
      mode '600'
      owner node['mongodb']['user']
      group node['mongodb']['group']
    end
  end
end


################################################################################
# Download MongoDB release - NOTE: This won't configure and start an instance

mongo_binaries = [
  'bsondump',
  'mongo',
  'mongod',
  'mongodump',
  'mongoexport',
  'mongofiles',
  'mongoimport',
  'mongooplog',
  'mongoperf',
  'mongorestore',
  'mongos',
  'mongosniff',
  'mongostat',
  'mongotop'
]

ark "mongodb" do
  url node['mongodb']['download']['src']
  version node['mongodb']['download']['version']
  checksum node['mongodb']['download']['checksum']
  has_binaries mongo_binaries.map{|b| "bin/#{b}"}
  action :install
end
