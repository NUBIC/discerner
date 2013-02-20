# This migration comes from discerner (originally 20130220163015)
class ReplaceIntegerTypeWithNumeric < ActiveRecord::Migration
  class ParameterType < ActiveRecord::Base
    include Discerner::Methods::Models::ParameterCategory
  end
  
  def up
    parameter_type = Discerner::ParameterType.find_by_name('integer')
    unless parameter_type.blank?
      parameter_type.name = 'numeric'
      parameter_type.save!
    end
  end

  def down
    parameter_type = Discerner::ParameterType.find_by_name('numeric')
    unless parameter_type.blank?
      parameter_type.name = 'integer'
      parameter_type.save!
    end
  end
end
