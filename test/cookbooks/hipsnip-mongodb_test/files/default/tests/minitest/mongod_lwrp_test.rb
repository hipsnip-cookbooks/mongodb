require File.expand_path('../support/helpers', __FILE__)
require 'mongo'

describe_recipe "hipsnip-mongodb_test::mongod_lwrp_test" do
  include Helpers::CookbookTest

  it "should set up and start a mongod instance" do
    connection = Mongo::MongoClient.new("127.0.0.1", 27018)
    connection['test'].command({'serverStatus' => 1})['ok'].must_equal 1
    connection.close
  end

  it "should set up configuration file" do
    file("/etc/mongodb/mongod-primary.conf").must_include "port = 27018"
    file("/etc/mongodb/mongod-primary.conf").must_include "dbpath = /var/lib/mongo_data/mongod-primary"
  end

  it "should create init file for service" do
    file("/etc/init/mongod-primary.conf").must_exist
  end
end