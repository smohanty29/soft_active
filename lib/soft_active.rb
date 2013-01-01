#!/usr/bin/ruby
# coding: utf-8

require "soft_active/version"
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
    def soft_active(options = {})
      raise ArgumentError, "Hash expected, got #{options.class.name}" unless !options.empty? && options.is_a?(Hash)

      default_options = {:column => :active}
      opts = default_options.merge(options)
      col = opts.delete(:column).to_sym
      raise ArgumentError, "Column for soft active not present, got #{col}" unless col.present? && self.column_names.include?(col.to_s)

      key = col
      _myvar ||= {}
      _myvar[key] ||= OpenStruct.new
      _myvar[key].col = key
      _myvar[key].options = opts

      scope :active_scope, lambda { where("#{self.table_name}.#{col} = ?", true) }
      scope :inactive_scope, lambda { where("#{self.table_name}.#{col} != ?", true) }
      default_scope { active_scope }

      # dynamic class methods to enable closure
      self.class.instance_eval do
        define_method "only_inactive" do
          unscoped.inactive_scope
        end

        define_method "with_inactive" do
          unscoped # Temp - how to retain prev default scope
        end

        define_method "only_active" do
          unscoped.active_scope
        end
      end

      # dynamic instance methods
      self.class_eval do
        define_method "set_#{col}" do
          set_col(_myvar[key], true)
        end

        define_method "unset_#{col}" do
          set_col(_myvar[key], false)
        end

        define_method "is_active?" do
          self.send("#{col}")
        end
      end
    end
  end

  module InstanceMethods
    RecordNotFound = Class.new(StandardError) unless defined?(RecordNotFound)

    private
    def set_col(parm, val)
      col = parm.col
      raise ArgumentError, "Column for soft active not present, got #{col}" unless col.present? && self.class.column_names.include?(col.to_s)
      self.send("#{col}=", val)
    end
  end

end

# Extend ActiveRecord's functionality
ActiveRecord::Base.send :include, SoftActive

