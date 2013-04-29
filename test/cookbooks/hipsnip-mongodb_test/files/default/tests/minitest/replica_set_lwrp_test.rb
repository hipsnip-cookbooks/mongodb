require File.expand_path('../support/helpers', __FILE__)
require 'mongo'

describe_recipe "hipsnip-mongodb_test::replica_set_lwrp_test" do
  include Helpers::CookbookTest

  it "should set up the individual nodes" do
    retries = 0
    begin
      connection = Mongo::MongoClient.new("127.0.0.1", 27017)
      connection['test'].command({'serverStatus' => 1})['ok'].must_equal 1
      connection.close

      connection = Mongo::MongoClient.new("127.0.0.1", 27019)
      connection['test'].command({'serverStatus' => 1})['ok'].must_equal 1
      connection.close

      connection = Mongo::MongoClient.new("127.0.0.1", 27020)
      connection['test'].command({'serverStatus' => 1})['ok'].must_equal 1
      connection.close
    rescue Mongo::ConnectionFailure
      raise if retries >= 3
      retries += 1
      sleep(10)
      retry
    end
  end

  it "should set up the replica set with the correct members" do
    retries = 0
    begin
      connection = Mongo::MongoReplicaSetClient.new(
                  ["127.0.0.1:27017", "127.0.0.1:27020"],
                  :name => 'play',
                  :read => :primary_preferred)

      connection['admin'].command({'replSetGetStatus' => 1})

      config = connection['local']['system']['replset'].find_one({"_id" => 'play'})
    rescue Mongo::ConnectionFailure
      raise if retries >= 3

      begin
        connection.close
      rescue
      end

      retries += 1
      sleep(10)

      connection = Mongo::MongoReplicaSetClient.new(
                  ["127.0.0.1:27017", "127.0.0.1:27019", "127.0.0.1:27020"],
                  :name => 'play',
                  :read => :primary_preferred)

      retry
    end

    config['members'].must_include({'_id' => 0, 'host' => '127.0.0.1:27017'})
    config['members'].must_include({'_id' => 2, 'host' => '127.0.0.1:27019', 'priority' => 0, 'hidden' => true})
    config['members'].must_include({'_id' => 3, 'host' => '127.0.0.1:27020'})

    connection.close
  end
end