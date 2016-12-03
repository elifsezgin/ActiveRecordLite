require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      curr_table_name = self.class.table_name
      source_name = source_name.to_s
      relation = DBConnection.execute(<<-SQL)
        SELECT
          #{source_name.pluralize}.*
        FROM
          #{curr_table_name}
        JOIN
          #{through_name}s
        ON
          #{curr_table_name}.#{through_options.foreign_key} = #{through_name}s.#{through_options.primary_key}
        JOIN
          #{source_name.pluralize}
        ON
          #{source_name.pluralize}.id = #{through_name}s.#{source_name}_id
        WHERE
          #{curr_table_name}.id = #{self.id}
      SQL
      source_name.to_s.camelize.constantize.new(relation.first)
    end
  end
end
