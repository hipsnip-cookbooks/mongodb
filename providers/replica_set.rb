#
# Cookbook Name:: hipsnip-mongodb
# Provider:: replica_set
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
  members = new_resource.members
  seed_list = members.collect{|n| n['host']}
  replica_set_name = new_resource.replica_set

  Chef::Log.info "Configuring replica set with #{members.length} member(s)"

  # Some basic validation

  raise "You have to pass in at least one member" if members.empty?

  unless (non_hash_members = members.reject{|n| n.is_a?(Hash)}).empty?
    raise "Some of the member configuations are not hashes:\n#{non_hash_members.inspect}"
  end

  unless (incomplete_members = members.reject{|n| n.key?('id') && n.key?('host')}).empty?
    raise "Some of the members are missing an 'id' or 'host' key:\n#{incomplete_members.inspect}"
  end

  unless (invalid_hosts = members.reject{|n| n['host'] =~ /^[a-z0-9\-\.]+:\d+$/}).empty?
    raise "Some of the member 'host' settings are the wrong format:\n#{invalid_hosts.inspect}"
  end


  ##############################################################################
  # First, let's see if we need to initiate the replica set

  Chef::Log.info "Checking to see if replica set is initialized"

  # Initial state of replica set in this pass
  #    Not updated even after calling "rs.initiate()"
  replica_set_initiated = false

  if members.length == 1
    connection = ::Mongo::MongoClient.new(*members[0]['host'].split(':'), :read => :primary_preferred)

    begin
      connection['admin'].command({'replSetGetStatus' => 1})
      replica_set_initiated = true
    rescue ::Mongo::OperationFailure => ex
      # unless it's telling us to initiate the replica set
      unless ex.message.include? 'run rs.initiate'
        raise # re-raise the error - we want to know about it
      end
    end
  else
    begin
      connection = ::Mongo::MongoReplicaSetClient.new(seed_list, :read => :primary_preferred, :connect_timeout => 10)
      connection['admin'].command({'replSetGetStatus' => 1})
      replica_set_initiated = true
    rescue ::Mongo::ConnectionFailure => ex
      # unless it's telling us that these members don't form a replica set
      unless ex.message.include? 'Cannot connect to a replica set using seeds'
        raise # re-raise the error - we want to know about it
      end

      # Replace connection with a single-member one
      # We'll use this in the next section to initiate the replica set
      connection = ::Mongo::MongoClient.new(*members[0]['host'].split(':'))
    end
  end


  ##############################################################################
  # Initiate replica set, if it's not done already

  unless replica_set_initiated
    Chef::Log.info "Initializing replica set..."

    replica_set_config = ::BSON::OrderedHash.new
    replica_set_config['_id'] = replica_set_name
    replica_set_config['members'] = members.collect{|member| generate_member_config(member)}.sort_by!{|n| n['_id']}

    begin
      connection['admin'].command({'replSetInitiate' => replica_set_config})
      Chef::Log.info "Replica set '#{replica_set_name}' initialized!"
    rescue ::Mongo::OperationFailure => ex
      raise ex unless ex.message.include? 'already initialized'
      Chef::Log.warn "Replica set already initialized"
    end

    # Check replica set health
    retries = 0
    begin
      connection = ::Mongo::MongoReplicaSetClient.new(seed_list, :name => replica_set_name, :read => :primary_preferred)
      connection['admin'].command({'replSetGetStatus' => 1})
    rescue ::Mongo::ConnectionFailure
      raise if retries >= node['mongodb']['node_check']['retries']
      Chef::Log.warn "Failed to get replica set status - might be initializing still"

      begin
        connection.close
      rescue
      end

      retries += 1
      sleep_time = retries * node['mongodb']['node_check']['timeout']
      Chef::Log.info "Waiting #{sleep_time} seconds and retrying..."
      sleep(sleep_time)
      retry
    end

    new_resource.updated_by_last_action(true)
  end


  ##############################################################################
  # Check to see if we need to re-configure - doesn't apply to new replica set

  if replica_set_initiated
    Chef::Log.info "Connecting to existing replica set"

    # Make sure we have a replica set connection for this
    unless connection.is_a?(::Mongo::MongoReplicaSetClient)
      begin
        connection.close
      rescue
      end

      connection = ::Mongo::MongoReplicaSetClient.new(seed_list, :name => replica_set_name, :connect_timeout => 10, :read => :primary_preferred)
    end


    Chef::Log.info "Getting current replica set config"
    retries = 0

    begin
      current_config = connection['local']['system']['replset'].find_one({"_id" => replica_set_name})
      current_members = current_config['members']
    rescue ::Mongo::ConnectionFailure
      raise if retries >= node['mongodb']['node_check']['retries']
      Chef::Log.warn "Failed to get replica set configuration"

      begin
        connection.close
      rescue
      end

      retries += 1
      sleep_time = retries * node['mongodb']['node_check']['timeout']
      Chef::Log.info "Waiting #{sleep_time} seconds and retrying..."
      sleep(sleep_time)

      connection = ::Mongo::MongoReplicaSetClient.new(seed_list, :name => replica_set_name, :connect_timeout => 10, :read => :primary_preferred)
      retry
    end


    Chef::Log.info "Generating new replica set config"

    new_config = ::BSON::OrderedHash.new
    new_config['_id'] = replica_set_name
    new_config['version'] = current_config['version'] + 1
    new_config['members'] = members.collect{|member| generate_member_config(member)}.sort_by!{|n| n['_id']}


    Chef::Log.info "Comparing new config to old config..."

    if new_config['members'] != current_members
      Chef::Log.info "Replica set configuration changed - current config:\n#{current_config.inspect}\nnew config:\n#{new_config.inspect}"
      Chef::Log.info "Updating replica set configuration..."

      begin
        connection['admin'].command({'replSetReconfig' => new_config})
      rescue ::Mongo::ConnectionFailure => ex # Reconfiguring closes all connections - this is normal
        Chef::Log.info "Connection closed, reconnecting..."
        connection = ::Mongo::MongoReplicaSetClient.new(seed_list, :name => replica_set_name, :connect_timeout => 10, :read => :primary_preferred)
      end

      Chef::Log.info "Verifying new replica set configuration..."
      retries = 0

      begin
        updated_config = connection['local']['system']['replset'].find_one({"_id" => replica_set_name})
      rescue ::Mongo::ConnectionFailure
        raise if retries >= node['mongodb']['node_check']['retries']
        Chef::Log.warn "Failed to get replica set configuration"

        begin
          connection.close
        rescue
        end

        retries += 1
        sleep_time = retries * node['mongodb']['node_check']['timeout']
        Chef::Log.info "Waiting #{sleep_time} seconds and retrying..."
        sleep(sleep_time)

        connection = ::Mongo::MongoReplicaSetClient.new(seed_list, :name => replica_set_name, :connect_timeout => 10, :read => :primary_preferred)
        retry
      end

      if updated_config['version'] == new_config['version'] && updated_config['members'] == new_config['members']
        Chef::Log.info "Replica set configuration updated and verified!"
      else
        Chef::Log.error "Failed to update replica set configuration! Server has:\n#{updated_config.inspect}\nWe tried to apply:\n#{new_config.inspect}"
      end

      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "Replica set configuration identical - nothing to do"
    end
  end
end


################################################################################
# Helpers

def generate_member_config(node)
  member_config = ::BSON::OrderedHash.new
  member_config['_id'] = node['id']
  member_config['host'] = node['host']

  # Only add extra properties if they were changed from their defaults
  member_config['buildIndexes'] = node['build_indexes'] unless node['build_indexes'].nil? || node['build_indexes'] == true
  member_config['priority'] = node['priority'] unless node['priority'].nil? || node['priority'] == 1.0
  member_config['arbiterOnly'] = node['arbiter_only'] unless node['arbiter_only'].nil? || node['arbiter_only'] == false
  member_config['slaveDelay'] = node['slave_delay'] unless node['slave_delay'].nil? || node['slave_delay'] == 0
  member_config['hidden'] = node['hidden'] unless node['hidden'].nil? || node['hidden'] == false
  member_config['votes'] = node['votes'] unless node['votes'].nil? || node['votes'] == 1
  member_config['tags'] = node['tags'] unless node['tags'].nil? || node['tags'].empty?

  member_config
end