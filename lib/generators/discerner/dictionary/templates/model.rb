class <%= @class_name %>
  attr_accessor :search
  
  def initialize(search)
    @search = search
  end
  
  def search(params=nil)
    
  end
  
  def export(params)
    
  end
  
  def export_formats
    ['csv', 'excel']
  end
end