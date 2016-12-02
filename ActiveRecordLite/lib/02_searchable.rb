require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    whereline = params.keys
      .map { |key| "#{key} = ?" }
      .join(" AND ")
    options = DBConnection.execute(<<-SQL, params.values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{whereline}
    SQL
    options.length == 0 ? [] : options.map { |o| self.new(o)}
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
