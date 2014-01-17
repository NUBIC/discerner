class Patient < ActiveRecord::Base
  def self.smethnic_groups
    [{ :foo => 'Hispanic or Latino', :bar => '1' }, { :foo => 'NOT Hispanic or Latino', :bar => '2' }]
  end

  def self.ethnic_groups
    [{ :name => 'Hispanic or Latino', :search_value => '1' }, { :name => 'NOT Hispanic or Latino', :search_value => '2' }]
  end

  def self.having_gender(sql)
    { :predicates => 'patients.gender in (?)',
      :values => sql[:values]
    }
  end
end
