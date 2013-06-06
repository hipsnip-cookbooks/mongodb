Description [![Build Status](https://travis-ci.org/hipsnip-cookbooks/mongodb.png)](https://travis-ci.org/hipsnip-cookbooks/mongodb)
===========
This is a cookbook for setting up MongoDB either as a single instance, or as a replica set.
You can use the resource providers (see below) for creating your own layout of nodes,
or the recipes to automatically set things up from node attributes.

Please note that this cookbook does not use the 10gen apt repository, and instead
downloads the required binaries from a given server. This gives you the ability to
point it at your own custom build of MongoDB (say with SSL included).


Compatibility
=============
Integration tested on 64bit Ubuntu `12.04` with Chef `11.4`, but assumed to work with other Debian-based
distros as well.

> NOTE: Running MongoDB on 32bit nodes is generally a bad idea, so we'll raise an exception
if someone tries to do it here.


Usage
=====
On the most basic level, just include the `hipsnip-mongodb::mongod` recipe to set up a single instance,
or the `hipsnip-mongodb::replica_set` recipe to set up a replica set. These will set sensible
defaults and will work fine out of the box, but you have the ability to customize them
using the attributes below.

> NOTE: The `replica_set` recipe will not work with Chef Solo. You can use the resource providers
below to manually build your own replica set, if you don't use Chef Server.


Attributes
==========

Please note that many of the attributes below directly map to settings in the MongoDB
configuration file. For more details on these settings, please refer to the
manual [here](http://docs.mongodb.org/manual/reference/configuration-options/).


### Download settings

    default['mongodb']['download']['version'] # The version to download (currently 2.4.3)
    default['mongodb']['download']['checksum'] # SHA256 checksum of the version archive

    # don't change these, unless you're running your own download server
    default['mongodb']['download']['host'] # The host we're downloading from (defaults to 'fastdl.mongodb.org')
    default['mongodb']['download']['subfolder'] # The subfolder we're downloading from (defaults to 'linux/')
    default['mongodb']['download']['cache_dir'] # Where to store the downloaded archive (defaults to '/usr/local/src')


### Global MongoDB configuration

These attributes are set globally on a node, and will apply to all instances
which are deployed on that node.

    default['mongodb']['user'] # The user to run MongoDB under (defaults to 'mongodb')
    default['mongodb']['group'] # The group to run MongoDB under (defaults to 'mongodb')
    default['mongodb']['group_id'] # Group ID for mongo group (defaults to 3500)

    default['mongodb']['log_dir'] # Log folder (defaults to '/var/log/mongo')
    default['mongodb']['data_dir'] # Data directory (defaults to '/var/lib/mongo_data')
    default['mongodb']['journal_dir'] # Journal directory (defaults to '/var/lib/mongo_journal')


    default['mongodb']['journal'] # Whether to turn journaling on (defaults to True)
    default['mongodb']['journal_commit_interval'] # journalCommitInterval setting (defaults to 100)

    default['mongodb']['syslog'] # Whether to send all log entries to syslog (defaults to True)
    default['mongodb']['log_append'] # Just leave this on true (defaults to True)
    default['mongodb']['log_cpu'] # Tell mongodb to periodically report CPU use in the logs (defaults to False)
    default['mongodb']['log_verbose'] # Whether to enable verbose logging (defaults to False)
    default['mongodb']['log_quiet'] # Reduce logging output (defaults to True)

    default['mongodb']['auth_enabled'] # Whether authentication is enabled (defaults to False)
    default['mongodb']['auth_keyfile'] # Authentication key file for replica sets (defaults to '')

    default['mongodb']['http_enabled'] # Whether to enable the HTTP interface (defaults to False)
    default['mongodb']['rest_enabled'] # Whether to enable the rest interface (defaults to False)
    default['mongodb']['scripting_enabled'] # Whether to allow scripting (defaults to True)
    default['mongodb']['tablescan_enabled'] # Whether to allow table scans (defaults to True)
    default['mongodb']['prealloc_enabled'] # Set to false to disable file preallocation (defaults to True)

    default['mongodb']['oplog'] # Oplog size in MB (defaults to 100)
    default['mongodb']['small_files'] # Set to true to reduce the amount preallocated (defaults to False)
    default['mongodb']['open_file_limit'] # The ulimit for open file descriptors set on the mongodb user (defaults to 64000)
    default['mongodb']['set_tcp_keepalive_time'] # Whether to update the TCP keepalive time on the system (defaults to False)
    default['mongodb']['tcp_keepalive_time'] # The new value for the TCP keepalive time (defaults to 300)


### Gem settings

    default['mongodb']['gem_version']['mongo'] # The version of the mongo gem to install (defaults to '1.8.5')
    default['mongodb']['gem_version']['bson_ext'] # The version of the bson_ext gem to install (defaults to '1.8.5')


### Misc.

    default['mongodb']['node_check']['retries'] # The number of times to retry health checks (defaults to 3)
    default['mongodb']['node_check']['timeout'] # Number of seconds to wait before retrying (defaults to 10)


### Instance configuration

These settings will be used by the `mongod` and `replica_set` recipes when configuring
a new mongodb instance.

    default['mongodb']['mongod']['port'] # The port to run the instance on (defaults to 27017)
    default['mongodb']['mongod']['bind_ip'] # Comma-separated list of IPs to bind to - leave blank to bind to all (defauts to '')

    # The attributes below are only used when setting up replica sets
	default['mongodb']['mongod']['replica_set'] # The replica set to join (defaults to 'my_set')
    default['mongodb']['mongod']['arbiter_only'] # defaults to False
    default['mongodb']['mongod']['build_indexes'] # defaults to True
    default['mongodb']['mongod']['hidden'] # defaults to False
    default['mongodb']['mongod']['priority'] # defaults to 1.0
    default['mongodb']['mongod']['tags'] # defaults to {}
    default['mongodb']['mongod']['slave_delay'] # defaults to 0
    default['mongodb']['mongod']['votes'] # defaults to 1

    # Use the value of this property when setting the address for a given replica set node
    #    leave blank to use 'bind_ip' - can't both be blank!
    default['mongodb']['node_address_attribute'] # defaults to 'fqdn'



Resources
=========

## hipsnip_mongodb_mongod

Sets up a mongod instance with the given parameters on the local host. It waits for
the node to come online, and performs a basic health check on it before handing
control back. Internally it uses the `hipsnip_mongodb_check_node` provider (see below) to
verify that the node is up.

### Actions

* create (default)

### Attributes

The value passed to `name` will be used as a postfix to the service name, configuration
file and data/journal directory of the new MongoDB instance. Using "default" as
the instance name has special meaning, and will cause the provider to not use a postfix.
See below for examples.

* bind_ip : The IP address to bind to - leave empty to bind to all addresses (defaults to "")
* port : The port to run the MongoDB service on (defaults to 27017)
* replica_set : The name of the replica set this node will be a part of - leave
blank to configure without a replica set (defaults to "")

> NOTE: Setting the `replica_set` attribute alone will not trigger replica set
creation. You need to use the `hipsnip_mongodb_replica_set` provider to do that.

### Examples

To set up a new MongoDB service called `mongod`, running on port `27018`,
with the config file `/etc/mongodb/mongd.conf` and data stored under `/var/lib/mongo_data/mongod`:

    hipsnip_mongodb_mongod "default" do
        port 27018
    end


To set up a new MongoDB service called `mongod-primary`, running on port `27019`,
with the config file `/etc/mongodb/mongod-primary.conf` and data stored under `/var/lib/mongo_data/mongod-primary`:

    hipsnip_mongodb_mongod "primary" do
        port 27019
        replica_set "my_set"
    end

It will also fill in the `replSet` configuration directive, but will not initialize
the replica set.



## hipsnip_mongodb_check_node

Used to check if a given node is up. If it can't connect, or if the health check fails,
it waits a few seconds and retries. The time spent waiting can be adjusted via
`node['mongodb']['node_check']['timeout']`, while the maximum number of retires can
be set in `node['mongodb']['node_check']['retries']`. The actual wait time increases
exponentially, calculated by `retries * timeout`.

> NOTE: On the first starup, MongoDB can spend quite some time pre-allocating data
and journal files. Depending on the speed of your hardware, and the oplog size
you specify, you may need to increase the timeout setting to avoid a failure during
your initial chef run.

### Actions

* run (default)

### Attributes

* node_ip (name attribute)
* port (defaults to 27017)

### Examples

To run a health check on the default node:

    hipsnip_mongodb_check_node "127.0.0.1" do
    	port 27017 # you could actually omit the port in this case
    end



## hipsnip_mongodb_replica_set

Takes a list of member nodes, and then it either initializes or updates the given
replica set (if it already exists). It also performs a health check after the replica
set initialization or reconfiguration, to make sure all is well before handing control
back. Failed health checks are reattempted - this can be controlled via `node['mongodb']['node_check']['timeout']`
and `node['mongodb']['node_check']['retries']`.

### Actions

* create (default)

### Attributes

* replica_set : The name of the replica set (name attribute)
* members : The list of member nodes

The member nodes are represented as hashes, and have the following fields:

* id (required) : The unique id of the member, between 0 and 255. Should not change between reconfigurations!
* host (required) : The address where the node can be reached in the `host:port` format.
* arbiter_only
* build_indexes
* hidden
* priority
* tags
* slave_delay
* votes

The last few are direct references to replica set node configuration directives - please
refer to the MongoDB documentation for details.

### Examples

To set up a replica set with a couple of nodes:

    hipsnip_mongodb_replica_set "my_set" do
        members [
            {
                'id' => 0,
                'host' => '127.0.0.1:27017'
            },
            {
                'id' => 1,
                'host' => '127.0.0.1:27018'
            }
        ]
    end



Development
============
Please refer to the Readme [here](https://github.com/hipsnip-cookbooks/cookbook-development/blob/master/README.md)


License and Author
==================

Author:: Adam Borocz ([on GitHub](https://github.com/motns))

Copyright:: 2013, HipSnip Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
