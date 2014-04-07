#
# Cookbook Name:: hipsnip-mongodb
# Provider:: mongod
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

action :create do
  instance_name = if node[:mongodb][:distro] == "tokumx" then "tokumx"
                  elsif new_resource.name == "default" then "mongod"
                  else "mongod-#{new_resource.name}"
                  end

  Chef::Log.info "Configuring MongoDB instance '#{instance_name}'..."

  config_file = if node[:mongodb][:distro] == "tokumx" then "/etc/tokumx.conf"
                else "/etc/mongodb/#{instance_name}.conf"
                end

  template config_file do
    source "mongod.conf.erb"
    mode '644'
    cookbook 'hipsnip-mongodb'
    variables({
      'instance_name' => instance_name,
      'bind_ip' => new_resource.bind_ip,
      'port' => new_resource.port,
      'db_path' => ::File.join(node['mongodb']['data_dir'], instance_name),
      'replica_set' => new_resource.replica_set
    })

    notifies :restart, "service[#{instance_name}]"
  end

  # Data dir
  directory ::File.join(node['mongodb']['data_dir'], instance_name) do
    owner node['mongodb']['user']
    group node['mongodb']['group']
    mode  '755'
    recursive true
  end

  # Journal dir
  directory ::File.join(node['mongodb']['journal_dir'], instance_name) do
    owner node['mongodb']['user']
    group node['mongodb']['group']
    mode  '755'
    recursive true
  end

  # Log dir
  directory ::File.join(node['mongodb']['log_dir'], instance_name) do
    owner node['mongodb']['user']
    group node['mongodb']['group']
    mode  '755'
    recursive true
  end

  link ::File.join(node['mongodb']['data_dir'], instance_name, 'journal') do
    to ::File.join(node['mongodb']['journal_dir'], instance_name)
  end
##############################################################
##############################################################

  case node["platform"]
  when "ubuntu"
    # Upstart script
    template "/etc/init/#{instance_name}.conf" do
      source "mongod.upstart.erb"
      mode '644'
      cookbook 'hipsnip-mongodb'
      variables(
        "config_file" => config_file,
        "instance_name" => instance_name
      )   
  
      notifies :restart, "service[#{instance_name}]"
    end 
  
  
    service instance_name do
      provider Chef::Provider::Service::Upstart
      action [:enable, :start]
    end 
  
  when "debian"
    # Init script
    template "/etc/init.d/#{instance_name}" do
      source "mongod.init.erb"
      mode '755'
      cookbook 'hipsnip-mongodb'
      variables(
        "config_file" => config_file,
        "instance_name" => instance_name
      )   
  
      notifies :restart, "service[#{instance_name}]"
    end 
  
  
    service instance_name do
      provider Chef::Provider::Service::Init::Debian
      action [:enable, :start]
    end 

  end 



##############################################################
##############################################################

  check_ip = (new_resource.bind_ip.empty?) ? "127.0.0.1" : new_resource.bind_ip

  hipsnip_mongodb_check_node check_ip do
    port new_resource.port

    # these will be ignored on first run, before the admin user is set up
    if node['mongodb']['auth_enabled']
      admin_user node['mongodb']['admin_user']['name']
      admin_pass node['mongodb']['admin_user']['password']
    end
  end

  # Set up Admin user
  hipsnip_mongodb_user node['mongodb']['admin_user']['name'] do
    password node['mongodb']['admin_user']['password']
    roles node['mongodb']['admin_user']['roles']
    database "admin"
    node_ip new_resource.bind_ip unless new_resource.bind_ip.empty?
    port new_resource.port
    only_if { node['mongodb']['auth_enabled'] }
  end

  new_resource.updated_by_last_action(true)
end
