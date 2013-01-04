module SoftActive
  module Associations
    module InstanceMethods
      def sa_update_associations(parm, val)
        col = parm.col
        sa_activable_associations.each do |association|
          unless association.klass.soft_active?
            SoftActive::Config.logger.warn "soft_active not enabled, skipped for dependent association #{self.class.name}/#{self.id}:#{association.name}"
            next
          end
          objects = sa_fetch_objects(association)
          objects.map{|o| o.set_active_col(val)}
          SoftActive::Config.logger.debug "soft_active dependent association update for #{self.class.name}/#{self.id}:#{association.name} #{objects.count} rows"
          # may be better way - TODO but for now save under instance var
          instance_variable_set(sa_ivar(association), objects)
        end
      end

      def sa_save_associations(parm, obj)
        sa_activable_associations.each do |association|
          next unless association.klass.soft_active?
          objects = instance_variable_get(sa_ivar(association))
          if objects.present? && objects.count > 0
            objects.map{|o| o.save!(:validate => false)}
            SoftActive::Config.logger.info "soft_active dependent association saved for #{self.class.name}/#{self.id}:#{association.name} #{objects.count} rows"
          end
        end
      end

      private

      def sa_activable_associations
        @_sa_activable_associations ||= self.class.reflect_on_all_associations.select do |association|
          #Rails.logger.debug "#{self.class.name} #{association.name}: #{association.klass} #{association.options}"
          # only for direct dependent with destroy and collections
          association.collection? && (association.options[:dependent] == :destroy) && !association.options[:through].present?
        end
      end

      def sa_fetch_objects(association)
        # self.send(association.name)
        # may not be foolproof yet - TODO
        query = "#{association.table_name}.#{association.foreign_key} = ?"
        query_p = [self.id]
        if association.type.present?
          query << " AND #{association.table_name}.#{association.type} = ?"
          query_p << self.class.name
        end
        association.klass.unscoped.where(query, *query_p)
      end

      def sa_ivar(association)
        "@_objects_for_#{association.name}"
      end
    end
  end
end



