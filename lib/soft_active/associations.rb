module SoftActive
  module Associations
    module InstanceMethods
      def update_associations(parm, val)
        activable_associations
      end

      private

      def activable_associations
        @_activable_associations ||= self.class.reflect_on_all_associations.select do |association|
          #puts "#{self.name} #{association.name}: #{association.klass} #{association.options}"
          association.options[:dependent].present?
        end
      end
    end
  end
end