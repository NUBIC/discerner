class Book
  def self.genres
    [
      {:name => 'Adventure', :unique_identifier => 'adventure', :display_order => 1, :collapse => true},
      {:name => 'Drama', :unique_identifier => 'drama', :display_order => 2, :collapse => false},
    ]
  end

  def self.generes
    [
      {:name => 'Adventure', :display_order => 1, :collapse => true},
      {:name => 'Drama', :unique_identifier => 'drama', :display_order => 2, :collapse => false},
    ]
  end
end
