#
# Cookbook Name:: hipsnip-mongodb
# Provider:: user
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
  node_ip = new_resource.node_ip
  port = new_resource.port
  database = new_resource.database
  username = new_resource.username
  password = new_resource.password
  roles = new_resource.roles
  admin_user = node['mongodb']['admin_user']['name']
  admin_pass = node['mongodb']['admin_user']['password']
  auth_enabled = node['mongodb']['auth_enabled']

  Chef::Log.info "Setting up User '#{username}' for database '#{database}' on MongoDB node at #{node_ip}:#{port}"

  unless auth_enabled
    raise 'You must have auth enabled before you can create users'
  end

  retries = 0

  begin
    # Try and work out if we're a replica set
    begin
      Chef::Log.info "Trying to connect to replica set for User creation"
      connection = ::Mongo::MongoReplicaSetClient.new(["#{node_ip}:#{port}"], :read => :primary_preferred, :connect_timeout => 10)
    rescue ::Mongo::ConnectionFailure => ex
      raise unless ex.message.include? 'Cannot connect to a replica set'
      Chef::Log.info "Trying to connect to single node for User creation"
      # This probably means we're just a single-node instance
      connection = ::Mongo::MongoClient.new(node_ip, port, :slave_ok => true)
    end

    db = connection['admin']

    begin
      db.authenticate(admin_user, admin_pass)
    rescue ::Mongo::AuthenticationError
      # Fail silently
      # This could be a genuine failure, or it could just be that
      # the credential setup provider hasn't run yet. If this really
      # is a failure, the serverStatus command below will catch it.
      Chef::Log.warn("Authentication as admin to MongoDB node at #{node_ip}:#{port} failed")
    end

    db = connection[database]

    # It appears that the Ruby driver does all the work for us here:
    # 1. If the user doesn't exist -> create it
    # 2. If the user exists -> update password and roles accordingly
    db.add_user(username, password, false, "roles" => roles)
  rescue ::Mongo::ConnectionFailure => ex
    # Expected error on first run of script
    unless ex.message.include? 'not master or secondary; cannot currently read from this replSet member'
      raise if retries >= node['mongodb']['node_check']['retries']
      Chef::Log.warn "Failed to set permissions for user '#{username}' on database '#{database}'"

      begin
        connection.close
      rescue
      end

      retries += 1
      sleep_time = retries * node['mongodb']['node_check']['timeout']
      Chef::Log.info "Waiting #{sleep_time} seconds and retrying..."
      sleep(sleep_time)
    end
  end

  Chef::Log.info "User #{username} for database #{database} created/updated on MongoDB node at #{node_ip}:#{port}"

  new_resource.updated_by_last_action(true)
end
