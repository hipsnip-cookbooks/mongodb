#
# Cookbook Name:: hipsnip-mongodb
# Provider:: check_node
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

action :run do
  node_ip = new_resource.node_ip
  port = new_resource.port
  username = new_resource.admin_user
  password = new_resource.admin_pass
  auth_enabled = node['mongodb']['auth_enabled']

  # If not passed in, load defaults from node attributes
  username = node['mongodb']['admin_user']['name'] if username.empty?
  password = node['mongodb']['admin_user']['password'] if password.empty?

  Chef::Log.info "Checking MongoDB node at #{node_ip}:#{port}"

  if auth_enabled
    if username.empty? || password.empty? # If we still don't have any credentials (unlikely)
      raise 'You must pass in "admin_user" and "admin_pass" for the health check if auth is enabled'
    end
  end

  retries = 0

  begin
    connection = ::Mongo::MongoClient.new(node_ip, port, :slave_ok => true)
    db = connection['admin']

    if auth_enabled
      begin
        db.authenticate(username, password)
      rescue ::Mongo::AuthenticationError
        # Fail silently
        # This could be a genuine failure, or it could just be that
        # the credential setup provider hasn't run yet. If this really
        # is a failure, the serverStatus command below will catch it.
        Chef::Log.warn("Authentication to MongoDB node at #{node_ip}:#{port} failed")
      end
    end

    res = db.command({'serverStatus' => 1})
    raise "serverStatus command failed on #{node_ip}:#{port}" if res.empty? or res['ok'] != 1
    connection.close
  rescue ::Mongo::ConnectionFailure
    Chef::Log.warn "Failed to connect to MongoDB node at #{node_ip}:#{port}"

    if retries < node['mongodb']['node_check']['retries']
      retries += 1
      sleep_time = retries * node['mongodb']['node_check']['timeout']

      Chef::Log.info "Waiting #{sleep_time} seconds and retrying..."
      sleep(sleep_time)
      retry
    end

    raise "MongoDB node at #{node_ip}:#{port} appears to be down"
  end

  Chef::Log.info "MongoDB node at #{node_ip}:#{port} is alive and well!"

  new_resource.updated_by_last_action(true)
end