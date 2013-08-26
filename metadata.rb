name             "hipsnip-mongodb"
maintainer       "HipSnip Ltd."
maintainer_email "adam@hipsnip.com"
license          "Apache 2.0"
description      "Installs/Configures mongodb"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.1.2"
supports 'ubuntu', ">= 12.04"

depends "sysctl", ">= 0.3.2"

recipe "hipsnip-mongodb", "Downloads and unpacks the required version of MongoDB - does not set up an instance"
recipe "hipsnip-mongodb::mongo_gem", "Installs the required version of the mongo and bson_ext gems"
recipe "hipsnip-mongodb::mongod", "Sets up a single mongod instance - don't use for replica sets"
recipe "hipsnip-mongodb::replica_set", "Automatically sets up and configures a replica set using Chef Search"