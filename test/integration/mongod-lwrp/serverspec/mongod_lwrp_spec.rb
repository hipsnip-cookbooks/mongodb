require 'serverspec'
# require 'mongo'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

describe file("/etc/mongodb/mongod-primary.conf") do
  it { should be_file }
  it { should contain "port = 27018" }
  it { should contain "dbpath = /var/lib/mongo_data/mongod-primary" }
end

describe port(27018) do
  it { should be_listening }
end

describe service('mongod-primary') do
  it { should be_enabled }
  it { should be_running }
end

describe command('mongo --host 127.0.0.1 --port 27018 --eval "printjson(db.serverStatus())"') do
  it { should return_stdout /"ok"\s*\:\s*1/ }
end

# @TODO - work out how to load gems in test environment
#
# describe "mongo server" do
#   it "should have status = ok" do
#     retries = 0
#     begin
#       connection = ::Mongo::MongoClient.new("127.0.0.1", 27018)
#       connection['test'].command({'serverStatus' => 1})['ok'].must_equal 1
#       connection.close
#     rescue ::Mongo::ConnectionFailure
#       raise if retries >= 3
#       retries += 1
#       sleep(10)
#       retry
#     end
#   end
# end