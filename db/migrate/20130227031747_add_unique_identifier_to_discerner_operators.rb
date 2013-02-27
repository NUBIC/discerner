class AddUniqueIdentifierToDiscernerOperators < ActiveRecord::Migration
  class Operator < ActiveRecord::Base
    include Discerner::Methods::Models::Operator
  end
  
  def change
    add_column :discerner_operators, :unique_identifier, :string
    
    Discerner::Operator.all.each do |p|
      p.unique_identifier = p.text.parameterize.underscore
      p.save!
    end
    remove_index :discerner_operators, :name => 'index_discerner_operators' 
    add_index :discerner_operators, [:unique_identifier, :deleted_at], :unique => true, :name => 'index_discerner_operators'
  end
end
