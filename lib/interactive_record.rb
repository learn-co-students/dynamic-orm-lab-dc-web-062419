require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

    def self.table_name
        self.to_s.downcase.pluralize
    end


    def self.column_names
        DB[:conn].results_as_hash = true

        sql = "PRAGMA table_info(#{table_name})"

        table_info = DB[:conn].execute(sql)
        column_names = []

        table_info.each do |column|
            column_names << column["name"]
        end

        column_names.compact
    end

    self.column_names.each do |column_name|
        attr_accessor column_name.to_sym
    end


    def initialize(options={})
        options.each do |property, value|
            self.send("#{property}=", value)
        end
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.delete_if {|n| n == "id"}.join(", ")
    end

    def values_for_insert
        values = []
        self.class.column_names.each do |column|
            values << "'#{send(column)}'" unless column == "id"
            # binding.pry
        end
        values.join(", ")
    end

    def save
        sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})" 
        DB[:conn].execute(sql) 
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        if self.column_names.include?("name")
            sql = "SELECT * FROM #{self.table_name} WHERE name = ? "
            our_code =  DB[:conn].execute(sql, name)
        else
            "Sorry, there is no column for 'name' in the table you are asking about."
        end
    end

    def self.find_by(search_term)
        DB[:conn].execute("SELECT * FROM students WHERE #{search_term.keys[0]} = '#{search_term.values[0]}'")
    end

end