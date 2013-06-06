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
node.set['mongodb']['downloaded'] = "#{node['mongodb']['download']['cache_dir']}/mongodb-linux-#{node['kernel']['machine']}-#{node['mongodb']['download']['version']}.tgz"
node.set['mongodb']['extracted'] = "#{node['mongodb']['download']['cache_dir']}/mongodb-linux-#{node['kernel']['machine']}-#{node['mongodb']['download']['version']}"


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


################################################################################
# Download MongoDB release - NOTE: This won't configure and start an instance

remote_file node['mongodb']['downloaded'] do
  source   node['mongodb']['download']['src']
  checksum node['mongodb']['download']['checksum']
  mode     0644
end

ruby_block 'Extract MongoDB archive' do
  block do
    `tar xzf #{node['mongodb']['downloaded']} -C #{node['mongodb']['download']['cache_dir']}`
    raise "Failed to extract MongoDB archive" unless ::File.exists?(node['mongodb']['extracted'])
  end

  action :create

  not_if do
    ::File.exists?(node['mongodb']['extracted'])
  end
end


ruby_block "Copy MongoDB executables" do
  block do
    Dir[::File::join(node['mongodb']['extracted'], 'bin', '*')].each do |exe|
        exe_name = ::File.basename(exe)
        exe_dest = ::File.join('/usr/bin', exe_name)

        Chef::Log.info "Looking at MongoDB executable '#{exe_name}':"

        downloaded_signature = `sha256sum #{exe} | cut -d ' ' -f 1`.strip
        Chef::Log.info "sha256 sum of downloaded file: #{downloaded_signature}"

        installed_signature = (::File.exists?(exe_dest) ? `sha256sum #{exe_dest} | cut -d ' ' -f 1` : '').strip
        Chef::Log.info "sha256 sum of current file: #{installed_signature}"

        if downloaded_signature != installed_signature
          Chef::Log.info "Copying MongoDB executable from '#{exe}' into '/usr/bin'"
          ::FileUtils.cp exe, exe_dest

          new_installed_signature = ::File.exists?(exe_dest) ? `sha256sum #{exe_dest} | cut -d ' ' -f 1`.strip : ''

          raise "Failed to copy MongoDB executable '#{exe_name}'" unless ::File.exists?(exe_dest) && downloaded_signature == new_installed_signature
        else
          Chef::Log.info "Checksums match, nothing to do"
        end
    end
  end

  action :create
end