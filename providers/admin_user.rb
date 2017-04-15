#
# Cookbook Name:: hipsnip-mongodb
# Provider:: admin_user
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

    connection = ::Mongo::MongoClient.new(node_ip, port, :slave_ok => true)
    res = connection['admin'].add_user(node['mongodb']['admin'], node['mongodb']['password'], false, { 'roles' => ['userAdmin']})
    connection.close
    
    Chef::Log.info "Added Admin User"
    new_resource.updated_by_last_action(true)
end