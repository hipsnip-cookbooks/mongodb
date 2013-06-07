## 1.1.0

* Fix for potential namespace issue, where the `Mongo` class is resolved incorrectly
* The defined "open file" ulimit is now correctly set for the `mongod` process
* Added support for (optionally) updating the tcp_keepalive time on a system - this is recommended by 10gen to resolve network problems with replica sets and shards. Functionality can be enabled by setting `set_tcp_keepalive_time` to `true`. The default is 300, but can be adjusted via `tcp_keepalive_time`.

## 1.1.1

* Update cookbook dependency for `sysctl` to make sure people won't end up with the `0.3.1` release, which had issues with the resource provider we use