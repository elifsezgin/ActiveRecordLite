require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key].nil? ? "#{name}_id".to_sym : options[:foreign_key]
    @primary_key = options[:primary_key].nil? ? :id  : options[:primary_key]
    @class_name = options[:class_name].nil? ? name.to_s.camelize : options[:class_name]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key].nil? ? "#{self_class_name.underscore}_id".to_sym : options[:foreign_key]
    @primary_key = options[:primary_key].nil? ? :id : options[:primary_key]
    @class_name = options[:class_name].nil? ? name.to_s.camelize.singularize : options[:class_name]
  end
end

module Associatable
  # Phase IIIb

  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options
    define_method(name) do
      foreign_key = options.foreign_key
      primary_key = options.primary_key
      target_class = options.model_class
      selected_models = target_class
        .where("#{target_class.table_name}.#{primary_key}" => self.send(foreign_key))
      selected_models[0]
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    define_method(name) do
      foreign_key = options.foreign_key
      primary_key = options.primary_key
      target_class = options.model_class
      selected_models = target_class
        .where("#{target_class.table_name}.#{foreign_key}" => self.send(primary_key))
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
