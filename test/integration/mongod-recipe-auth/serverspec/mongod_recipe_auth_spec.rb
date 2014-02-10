require 'serverspec'
# require 'mongo'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

describe file("/etc/mongodb/mongod.conf") do
  it { should be_file }
  it { should contain "port = 27017" }
  it { should contain "dbpath = /var/lib/mongo_data/mongod" }
  it { should contain "auth = true" }
end

describe file("/etc/init/mongod.conf") do
  it { should be_file }
end

describe port(27017) do
  it { should be_listening }
end

describe service('mongod') do
  it { should be_enabled }
  it { should be_running }
end

describe command('mongo --host 127.0.0.1 --port 27017 -u administrator -p testpass --eval "printjson(db.serverStatus())" admin') do
  it { should return_stdout /"ok"\s*\:\s*1/ }
end