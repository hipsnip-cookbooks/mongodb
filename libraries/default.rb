#
# Cookbook Name:: hipsnip-mongodb
# Library:: helpers
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

module HipSnip
  module MongoDB
    module Helpers
      def member_from_node(node)
        node_config = node['mongodb']['mongod']
        host_address = if node['mongodb']['node_address_attribute'].empty?
                         node_config['bind_ip'].split(",")[0]
                       else node[node['mongodb']['node_address_attribute']]
                       end

        {
          'id' => node_config['member_id'],
          'host' => "#{host_address}:#{node_config['port']}",
          'arbiter_only' => node_config['arbiter_only'],
          'build_indexes' => node_config['build_indexes'],
          'hidden' => node_config['hidden'],
          'priority' => node_config['priority'],
          'tags' => node_config['tags'],
          'slave_delay' => node_config['slave_delay'],
          'votes' => node_config['votes']
        }
      end
    end
  end
end