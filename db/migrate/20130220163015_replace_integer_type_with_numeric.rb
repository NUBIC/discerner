class ReplaceIntegerTypeWithNumeric < ActiveRecord::Migration
  class ParameterType < ActiveRecord::Base
    include Discerner::Methods::Models::ParameterCategory
  end
  
  def up
    parameter_type = Discerner::ParameterType.find_by_name('integer')
    parameter_type.name = 'numeric'
    parameter_type.save!
  end

  def down
    parameter_type = Discerner::ParameterType.find_by_name('numeric')
    parameter_type.name = 'integer'
    parameter_type.save!
  end
end
