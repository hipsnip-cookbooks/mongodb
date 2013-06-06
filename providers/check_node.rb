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

    Chef::Log.info "Checking MongoDB node at #{node_ip}:#{port}"

    retries = 0

    begin
      connection = ::Mongo::MongoClient.new(node_ip, port, :slave_ok => true)
      res = connection['test'].command({'serverStatus' => 1}) # The DB name doesn't actually matter
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