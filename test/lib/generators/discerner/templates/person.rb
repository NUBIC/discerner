class Person < ActiveRecord::Base
  attr_accessible :gender
  
  def self.ethnic_groups
    ['Hispanic or Latino', 'NOT Hispanic or Latino']
  end
end
