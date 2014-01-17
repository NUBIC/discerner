class ChangeSearchAttributeToMethod < ActiveRecord::Migration
  class Search < ActiveRecord::Base
    include Discerner::Methods::Models::Parameter
  end

  def self.up
    add_column :discerner_parameters, :search_method, :string

    Discerner::Parameter.order(:id).each do |p|
      p.search_method = p.search_attribute
      p.save!
    end

    remove_index :discerner_parameters, :name => 'index_discerner_parameters'
    remove_column :discerner_parameters, :search_attribute
  end

  def self.down
    add_column :discerner_parameters, :search_attribute, :string

    Discerner::Parameter.order(:id).each do |p|
      p.search_attribute = p.search_method
      p.save!
    end

    remove_column :discerner_parameters, :search_method
    add_index :discerner_parameters, [:search_model, :search_attribute, :parameter_category_id, :deleted_at], :unique => true, :name => 'index_discerner_parameters'
  end
end
