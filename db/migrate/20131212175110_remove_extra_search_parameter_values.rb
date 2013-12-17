class RemoveExtraSearchParameterValues < ActiveRecord::Migration
  def up
    sql = Discerner::SearchParameterValue.joins(:search_parameter => {:parameter => :parameter_type}).where("discerner_parameter_types.name = 'combobox' and chosen is null").to_sql
    search_parameter_values_array = Discerner::SearchParameterValue.find_by_sql(sql)
    search_parameter_values_array.each{|r| r.delete}
  end

  def down
  end
end
