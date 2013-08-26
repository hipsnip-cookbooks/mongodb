#
# Cookbook Name:: hipsnip-mongodb
# Attributes:: default
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

################################################################################
# Download and install

default['mongodb']['download']['version'] = '2.4.6'
default['mongodb']['download']['checksum'] = '65bf44b1eaaf35052f53e1700bfe890b0951f65600716f0c12fd4db05421383c' # SHA-256
# don't change this, unless you're running your own download server
default['mongodb']['download']['host'] = 'fastdl.mongodb.org'
default['mongodb']['download']['subfolder'] = 'linux/'
default['mongodb']['download']['cache_dir'] = '/usr/local/src'


################################################################################
# Generic configuration (will be the same for all instances on this node)

default['mongodb']['user'] = 'mongodb'
default['mongodb']['group_id'] = 3500
default['mongodb']['group'] = 'mongodb'

# Paths
default['mongodb']['log_dir'] = '/var/log/mongo'
# we'll create a new folder in these paths for each instance
default['mongodb']['data_dir'] = '/var/lib/mongo_data'
default['mongodb']['journal_dir'] = '/var/lib/mongo_journal'

# Journaling
default['mongodb']['journal'] = true
default['mongodb']['journal_commit_interval'] = 100 # ms

# Logging
default['mongodb']['syslog'] = true # Having this ON means all log entries will go to syslog rather than to the log file (version >2.1)
default['mongodb']['log_append'] = true
default['mongodb']['log_cpu'] = false
default['mongodb']['log_verbose'] = false
default['mongodb']['log_quiet'] = true

# Authentication
default['mongodb']['auth_enabled'] = false
default['mongodb']['auth_keyfile'] = '' # Only if auth enabled

# Admin & Monitoring
default['mongodb']['http_enabled'] = false
default['mongodb']['rest_enabled'] = false
default['mongodb']['scripting_enabled'] = true
default['mongodb']['tablescan_enabled'] = true
default['mongodb']['prealloc_enabled'] = true

# Replication
default['mongodb']['oplog'] = 100 # MB

# misc
default['mongodb']['small_files'] = false
default['mongodb']['open_file_limit'] = 64000 # 10gen recommendation

default['mongodb']['set_tcp_keepalive_time'] = false
default['mongodb']['tcp_keepalive_time'] = 300 # 10gen recommendation


####################################################
# Gems

default['mongodb']['gem_version']['mongo'] = '1.9.2'
default['mongodb']['gem_version']['bson_ext'] = '1.9.2'


####################################################
# Settings for node health check provider

default['mongodb']['node_check']['retries'] = 3
default['mongodb']['node_check']['timeout'] = 10 # seconds
# @note - timeout is exponential - the actual timeout is retry*timeout


