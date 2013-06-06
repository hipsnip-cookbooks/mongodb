require File.expand_path('../support/helpers', __FILE__)
require 'mongo'

describe_recipe "hipsnip-mongodb_test::mongod_recipe" do
  include Helpers::CookbookTest

  it "should set up and start a mongod instance" do
    retries = 0
    begin
      connection = ::Mongo::MongoClient.new("127.0.0.1", 27017)
      connection['test'].command({'serverStatus' => 1})['ok'].must_equal 1
      connection.close
    rescue ::Mongo::ConnectionFailure
      raise if retries >= 3
      retries += 1
      sleep(10)
      retry
    end
  end

  it "should set up a default configuration file" do
    file("/etc/mongodb/mongod.conf").must_include "port = 27017"
    file("/etc/mongodb/mongod.conf").must_include "dbpath = /var/lib/mongo_data/mongod"
  end

  it "should create init file for service" do
    file("/etc/init/mongod.conf").must_exist
  end
end