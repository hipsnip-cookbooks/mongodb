## 1.2.0

* Support for authentication in both single node and replica set scenarios
  * Includes new LWRP for setting up user permissions on a database
* Support for running on Debian 7.x
* Update to latest version of MongoDB (2.4.10) and Ruby driver (1.10.0)
* Fix for an issue where on some server images the native extensions used by the Ruby driver would fail to compile, due to missing build tools. We now include the `build-essential` cookbook as a dependency when installing the Ruby driver.
* Fix for a small issue where configuration values that were set to their defaults caused warnings to appear in the logs
* Binaries are now downloaded and installed using the `ark` cookbook from Opscode, offering a cleaner, more robust solution
* Integration tests were updated to follow the final Test Kitchen `1.0` conventions


## 1.1.2

* Update to latest version for MongoDB server (2.4.6) and Gems (1.9.2)
* Update dependencies for test suite (Test Kitchen, Strainer, Chefspec)


## 1.1.1

* Update cookbook dependency for `sysctl` to make sure people won't end up with the `0.3.1` release, which had issues with the resource provider we use


## 1.1.0

* Fix for potential namespace issue, where the `Mongo` class is resolved incorrectly
* The defined "open file" ulimit is now correctly set for the `mongod` process
* Added support for (optionally) updating the tcp_keepalive time on a system - this is recommended by 10gen to resolve network problems with replica sets and shards. Functionality can be enabled by setting `set_tcp_keepalive_time` to `true`. The default is 300, but can be adjusted via `tcp_keepalive_time`.