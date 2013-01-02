#!/usr/bin/ruby
# coding: utf-8

require "soft_active/version"
require 'soft_active/associations'
require 'ostruct'

# Requires :boolean attribute named 'active'
# Warning, this sets default_scope to :only_active,
#   overriding any existing default_scope

#TODO: use http://apidock.com/rails/ActiveSupport/Concern
module SoftActive
  def self.included(klass)
    klass.extend SoftActive::ClassMethods
    klass.send(:include, SoftActive::InstanceMethods)
  end

  module ClassMethods
    def soft_active?
      self.instance_methods.include? :soft_active_defined?
    end

    def soft_active(options = {})
      # options = {:column => :column_name, :dependent_cascade => true|false, :dependent_associations => [:comments, :blogs]}
      raise ArgumentError, "Hash expected, got #{options.class.name}" unless options.is_a?(Hash)

      default_options = {:column => :active}
      opts = default_options.merge(options)
      col = opts.delete(:column).to_sym
      raise ArgumentError, "Column for soft active not present, got #{col}" unless col.present? && self.column_names.include?(col.to_s)

      key = col
      _myvar ||= {}
      _myvar[key] ||= OpenStruct.new
      _myvar[key].col = key
      _myvar[key].options = opts

      # dynamic class methods to enable closure
      self.class.instance_eval do
        define_method "only_in#{col.to_s}" do
          unscoped.where("#{self.table_name}.#{col} != ?", true)
        end

        define_method "with_in#{col.to_s}" do
          unscoped # Temp - how to retain prev default scope
        end

        define_method "only_#{col.to_s}" do
          where("#{self.table_name}.#{col} = ?", true) 
        end
      end

      default_scope { self.send "only_#{col.to_s}" }

      # dynamic instance methods
      self.class_eval do
        define_method "set_#{col}" do # unset_active
          set_col(_myvar[key], true)
        end

        define_method "unset_#{col}" do # unset_active
          set_col(_myvar[key], false)
        end

        define_method "is_#{col}?" do # is_active?
          self.send("#{col}")
        end

        define_method "soft_active_defined?" do
          true
        end
      end
    end
  end

  module InstanceMethods
    RecordNotFound = Class.new(StandardError) unless defined?(RecordNotFound)

    private
    include SoftActive::Associations::InstanceMethods

    def set_col(parm, val)
      col = parm.col
      raise ArgumentError, "Column for soft active not present, got #{col}" unless col.present? && self.class.column_names.include?(col.to_s)
      update_associations(parm, val)
      self.send("#{col}=", val)
    end
  end

end

# Extend ActiveRecord's functionality
ActiveRecord::Base.send :include, SoftActive

