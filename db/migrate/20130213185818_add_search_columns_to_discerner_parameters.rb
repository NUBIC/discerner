class AddSearchColumnsToDiscernerParameters < ActiveRecord::Migration
  class ParameterCategory < ActiveRecord::Base
    include Discerner::Methods::Models::ParameterCategory
  end

  class Parameter < ActiveRecord::Base
    include Discerner::Methods::Models::Parameter
  end

  def self.up
    add_column :discerner_parameters, :search_model, :string
    add_column :discerner_parameters, :search_attribute, :string

    Discerner::Parameter.order(:id).each do |p|
      p.search_attribute = p.database_name
      p.search_model  = p.parameter_category.parameterized_name
      p.save!
    end

    remove_index :discerner_parameters, :name => 'index_discerner_parameters'
    remove_column :discerner_parameters, :database_name
    add_index :discerner_parameters, [:search_model, :search_attribute, :parameter_category_id, :deleted_at], :unique => true, :name => 'index_discerner_parameters'
  end

  def self.down
    add_column :discerner_parameters, :database_name, :string

    Discerner::Parameter.order(:id).each do |p|
      p.database_name = p.search_attribute
      p.save!
    end

    remove_index :discerner_parameters, :name => 'index_discerner_parameters'
    remove_column :discerner_parameters, :search_model
    remove_column :discerner_parameters, :search_attribute
    add_index :discerner_parameters, [:database_name, :deleted_at], :unique => true, :name => 'index_discerner_parameters'
  end
end
