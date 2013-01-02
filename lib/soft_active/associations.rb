module SoftActive
  class Associations
    def self.update_associations(instance, parm, val)
      col = parm.col
      activable_associations(instance).each do |association|
        next unless association.klass.soft_active?
        objects = fetch_objects(instance, association)
        objects.map{|o| o.set_active_col(val)}
        # may be better way - TODO but for now save under instance var
        instance_variable_set(ivar(instance, association), objects)
      end
    end

    def self.save_associations(instance, parm, obj)
      activable_associations(instance).each do |association|
        next unless association.klass.soft_active?
        objects = instance_variable_get(ivar(instance, association))
        objects.map(&:save) if objects.present? && objects.count > 0
      end
    end

    private

    def self.activable_associations(instance)
      @_activable_associations ||= instance.class.reflect_on_all_associations.select do |association|
        puts "#{instance.class.name} #{association.name}: #{association.klass} #{association.options}"
        association.collection? && association.options[:dependent].present? && (association.options[:dependent] == :destroy)
      end
    end

    def self.fetch_objects(instance, association)
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

    def self.ivar(instance, association)
      "@_objects_for_#{association.name}"
    end
  end
end