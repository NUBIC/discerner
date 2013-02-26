class Patient < ActiveRecord::Base
  attr_accessible :gender
  
  def self.ethnic_groups
    ['Hispanic or Latino', 'NOT Hispanic or Latino']
  end
  
  def self.having_gender(sql)
    { :predicates => 'patients.gender in (?)',
      :values => sql[:values]
    }
  end
end
