actions :run
default_action :run

attribute :node_ip, :kind_of => String, :name_attribute => true
attribute :port, :kind_of => Integer, :default => 27017
attribute :admin_user, :kind_of => String, :default => ""
attribute :admin_pass, :kind_of => String, :default => ""