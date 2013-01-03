# Active record dependencies
# require 'active_record/persistence'
# require 'active_record/base'
# require 'active_record/relation'
# require 'active_record/callbacks'

require 'rubygems'
require 'active_record'

require 'soft_active'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", 
                                       :database => File.dirname(__FILE__) + "/db/test.sqlite3")
