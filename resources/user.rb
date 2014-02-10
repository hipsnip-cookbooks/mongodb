actions :create
default_action :create

attribute :username, :kind_of => String, :name_attribute => true
attribute :password, :kind_of => String, :required => true
attribute :roles, :kind_of => Array, :required => true
attribute :database, :kind_of => String, :default => "admin"
attribute :node_ip, :kind_of => String, :default => "127.0.0.1"
attribute :port, :kind_of => Integer, :default => 27017