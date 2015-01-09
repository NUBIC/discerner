class AddHiddenToDiscernerParameters < ActiveRecord::Migration
  def change
    add_column :discerner_parameters, :hidden_in_export, :boolean, default: false
    add_column :discerner_parameters, :hidden_in_search, :boolean, default: false
    Discerner::Parameter.all.each do |parameter|
      parameter.hidden_in_export = false
      parameter.hidden_in_search = false
      parameter.save!
    end
  end
end
