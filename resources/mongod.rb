actions :create
default_action :create

attribute :bind_ip, :kind_of => String, :default => ''
attribute :port, :kind_of => Integer, :default => 27017
attribute :replica_set, :kind_of => String, :default => ''