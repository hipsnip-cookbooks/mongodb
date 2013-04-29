actions :create
default_action :create

attribute :replica_set, :kind_of => String, :name_attribute => true
attribute :members, :kind_of => Array, :required => true