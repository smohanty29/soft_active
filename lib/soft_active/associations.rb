module SoftActive
  module Associations
    module InstanceMethods
      def sa_update_associations(instance, parm, val)
        col = parm.col
        sa_activable_associations(instance).each do |association|
          unless association.klass.soft_active?
            Rails.logger.warn "soft_active not enabled, skipped for dependent association #{instance.class.name}/#{instance.id}:#{association.name}"
            next
          end
          objects = sa_fetch_objects(instance, association)
          objects.map{|o| o.set_active_col(val)}
          Rails.logger.debug "soft_active dependent association update for #{instance.class.name}/#{instance.id}:#{association.name} updated for #{objects.count} rows"
          # may be better way - TODO but for now save under instance var
          instance_variable_set(sa_ivar(instance, association), objects)
        end
      end

      def sa_save_associations(instance, parm, obj)
        sa_activable_associations(instance).each do |association|
          next unless association.klass.soft_active?
          objects = instance_variable_get(sa_ivar(instance, association))
          if objects.present? && objects.count > 0
            objects.map{|o| o.save!(:validate => false)}
            Rails.logger.info "soft_active dependent association save for #{instance.class.name}/#{instance.id}:#{association.name} updated for #{objects.count} rows"
          end
        end
      end

      private

      def sa_activable_associations(instance)
        @_sa_activable_associations ||= instance.class.reflect_on_all_associations.select do |association|
          #Rails.logger.debug "#{instance.class.name} #{association.name}: #{association.klass} #{association.options}"
          # only for direct dependent with destroy and collections
          association.collection? && (association.options[:dependent] == :destroy) && !association.options[:through].present?
        end
      end

      def sa_fetch_objects(instance, association)
        # instance.send(association.name)
        # may not be foolproof yet - TODO
        query = "#{association.table_name}.#{association.foreign_key} = ?"
        query_p = [instance.id]
        if association.type.present?
          query << " AND #{association.table_name}.#{association.type} = ?"
          query_p << instance.class.name
        end
        association.klass.unscoped.where(query, *query_p)
      end

      def sa_ivar(instance, association)
        "@_objects_for_#{association.name}"
      end
    end
  end
end



