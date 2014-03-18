require 'serverspec'
# require 'mongo'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

################################################################################
# Node one

describe file("/etc/mongodb/mongod-one.conf") do
  it { should be_file }
  it { should contain "port = 27017" }
  it { should contain "dbpath = /var/lib/mongo_data/mongod-one" }
end

describe port(27017) do
  it { should be_listening }
end

describe service('mongod-one') do
  it { should be_enabled }
  it { should be_running }
end

describe command('mongo --host 127.0.0.1 --port 27017 --eval "printjson(db.serverStatus())"') do
  it { should return_stdout /"ok"\s*\:\s*1/ }
end

# @NOTE: Node two should not be part of replica set at this point (though it is still running)

################################################################################
# Node three

describe file("/etc/mongodb/mongod-three.conf") do
  it { should be_file }
  it { should contain "port = 27019" }
  it { should contain "dbpath = /var/lib/mongo_data/mongod-three" }
end

describe port(27019) do
  it { should be_listening }
end

describe service('mongod-three') do
  it { should be_enabled }
  it { should be_running }
end

describe command('mongo --host 127.0.0.1 --port 27019 --eval "printjson(db.serverStatus())"') do
  it { should return_stdout /"ok"\s*\:\s*1/ }
end


################################################################################
# Node four

describe file("/etc/mongodb/mongod-four.conf") do
  it { should be_file }
  it { should contain "port = 27020" }
  it { should contain "dbpath = /var/lib/mongo_data/mongod-four" }
end

describe port(27020) do
  it { should be_listening }
end

describe service('mongod-four') do
  it { should be_enabled }
  it { should be_running }
end

describe command('mongo --host 127.0.0.1 --port 27020 --eval "printjson(db.serverStatus())"') do
  it { should return_stdout /"ok"\s*\:\s*1/ }
end


# @TODO - port below minitest specs when we work out how to get mongo gem in env
#
# describe_recipe "hipsnip-mongodb_test::replica_set_lwrp_test" do
#   include Helpers::CookbookTest

#   it "should set up the individual nodes" do
#     retries = 0
#     begin
#       connection = ::Mongo::MongoClient.new("127.0.0.1", 27017)
#       connection['test'].command({'serverStatus' => 1})['ok'].must_equal 1
#       connection.close

#       connection = ::Mongo::MongoClient.new("127.0.0.1", 27019)
#       connection['test'].command({'serverStatus' => 1})['ok'].must_equal 1
#       connection.close

#       connection = ::Mongo::MongoClient.new("127.0.0.1", 27020)
#       connection['test'].command({'serverStatus' => 1})['ok'].must_equal 1
#       connection.close
#     rescue ::Mongo::ConnectionFailure
#       raise if retries >= 3
#       retries += 1
#       sleep(10)
#       retry
#     end
#   end

#   it "should set up the replica set with the correct members" do
#     retries = 0
#     begin
#       connection = ::Mongo::MongoReplicaSetClient.new(
#                    ["127.0.0.1:27017", "127.0.0.1:27020"],
#                    :name => 'play',
#                    :read => :primary_preferred)

#       connection['admin'].command({'replSetGetStatus' => 1})

#       config = connection['local']['system']['replset'].find_one({"_id" => 'play'})
#     rescue ::Mongo::ConnectionFailure
#       raise if retries >= 3

#       begin
#         connection.close
#       rescue
#       end

#       retries += 1
#       sleep(10)

#       connection = ::Mongo::MongoReplicaSetClient.new(
#                    ["127.0.0.1:27017", "127.0.0.1:27019", "127.0.0.1:27020"],
#                    :name => 'play',
#                    :read => :primary_preferred)

#       retry
#     end

#     config['members'].must_include({'_id' => 0, 'host' => '127.0.0.1:27017'})
#     config['members'].must_include({'_id' => 2, 'host' => '127.0.0.1:27019', 'priority' => 0, 'hidden' => true})
#     config['members'].must_include({'_id' => 3, 'host' => '127.0.0.1:27020'})

#     connection.close
#   end
# end