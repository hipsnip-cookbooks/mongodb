#
# Cookbook Name:: hipsnip-mongodb-test
# Recipe:: mongod_lwrp
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

node.set['mongodb']['small_files'] = true

include_recipe "hipsnip-mongodb_test::default"

hipsnip_mongodb_mongod "one" do
  bind_ip "127.0.0.1"
  port 27017
  replica_set 'play'
end

hipsnip_mongodb_mongod "two" do
  bind_ip "127.0.0.1"
  port 27018
  replica_set 'play'
end

hipsnip_mongodb_mongod "three" do
  bind_ip "127.0.0.1"
  port 27019
  replica_set 'play'
end

hipsnip_mongodb_replica_set "play" do
  members [
    {
      'id' => 0,
      'host' => '127.0.0.1:27017'
    },
    {
      'id' => 1,
      'host' => '127.0.0.1:27018'
    },
    {
      'id' => 2,
      'host' => '127.0.0.1:27019',
      'priority' => 0,
      'hidden' => true
    }
  ]
end


# Add a new node

hipsnip_mongodb_mongod "four" do
  bind_ip "127.0.0.1"
  port 27020
  replica_set 'play'
end

hipsnip_mongodb_replica_set "play" do
  members [
    {
      'id' => 0,
      'host' => '127.0.0.1:27017'
    },
    {
      'id' => 1,
      'host' => '127.0.0.1:27018'
    },
    {
      'id' => 2,
      'host' => '127.0.0.1:27019',
      'priority' => 0,
      'hidden' => true
    },
    {
      'id' => 3,
      'host' => '127.0.0.1:27020'
    }
  ]
end


# Remove a node

hipsnip_mongodb_replica_set "play" do
  members [
    {
      'id' => 0,
      'host' => '127.0.0.1:27017'
    },
    {
      'id' => 2,
      'host' => '127.0.0.1:27019',
      'priority' => 0,
      'hidden' => true
    },
    {
      'id' => 3,
      'host' => '127.0.0.1:27020'
    }
  ]
end
