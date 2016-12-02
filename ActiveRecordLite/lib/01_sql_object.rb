require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns

    @data ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    @columns = @data[0].map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |column_name|
      define_method("#{column_name}=") do |value|
        attributes[column_name.to_sym] = value
      end
      define_method("#{column_name}") do
        attributes[column_name.to_sym]
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name ? table_name : self.table_name

  end

  def self.table_name
    @table_name ||= self.name.tableize
  end

  def self.all
    all_db = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    self.parse_all(all_db)
  end

  def self.parse_all(results)
    all_objects = []
    results.each do |options|
      all_objects << self.new(options)
    end
    all_objects
  end

  def self.find(id)
    options = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = #{id}
    SQL
    return nil if options.empty?
    self.new(options[0])
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      raise Exception, "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name.to_sym)
      self.send("#{attr_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def insert
    col_names = self.class.columns[1..-1].map(&:to_s).join(", ")
    question_marks = (["?"] * (self.class.columns.count-1)).join(", ")
    DBConnection.execute(<<-SQL, attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_values = self.class.columns[1..-1].map { |attr_name| "#{attr_name} = ?"}.join(", ")
    DBConnection.execute(<<-SQL, attribute_values.drop(1), attribute_values.take(1))
      UPDATE
        #{self.class.table_name}
      SET
        #{set_values}
      WHERE
        id = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
