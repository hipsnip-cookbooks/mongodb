require 'serverspec'
# require 'mongo'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

# This scenario is fully tested by "replica_set_lwrp"
# Here we're just checking that cluster nodes are up, and that authentication works

################################################################################
# Node one

describe port(27017) do
  it { should be_listening }
end

describe service('mongod-one') do
  it { should be_enabled }
  it { should be_running }
end

describe command('mongo --host 127.0.0.1 --port 27017 -u administrator -p testpass --eval "printjson(db.serverStatus())" admin') do
  it { should return_stdout /"ok"\s*\:\s*1/ }
end

# @NOTE: Node two should not be part of replica set at this point (though it is still running)

################################################################################
# Node three

describe port(27019) do
  it { should be_listening }
end

describe service('mongod-three') do
  it { should be_enabled }
  it { should be_running }
end

describe command('mongo --host 127.0.0.1 --port 27019 -u administrator -p testpass --eval "printjson(db.serverStatus())" admin') do
  it { should return_stdout /"ok"\s*\:\s*1/ }
end


################################################################################
# Node four

describe port(27020) do
  it { should be_listening }
end

describe service('mongod-four') do
  it { should be_enabled }
  it { should be_running }
end

describe command('mongo --host 127.0.0.1 --port 27020 -u administrator -p testpass --eval "printjson(db.serverStatus())" admin') do
  it { should return_stdout /"ok"\s*\:\s*1/ }
end
