#
# Cookbook Name:: hipsnip-mongodb-test
# Recipe:: mongod_recipe_auth
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

# Set up a single mongod instance with authentication using the mongod recipe
node.set['mongodb']['auth_enabled'] = true

# Set these explicitly for test (should also work with just defaults)
node.set['mongodb']['admin_user']['name'] = "administrator"
node.set['mongodb']['admin_user']['password'] = "testpass"

# Just augment the default test case with authentication
include_recipe "hipsnip-mongodb_test::mongod_recipe"