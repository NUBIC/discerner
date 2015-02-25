class Event < ActiveRecord::Base
  has_many :discerner_search_namespaces, class_name: 'Discerner::SearchNamespace', as: :namespace
  has_many :discerner_searches, through: :discerner_search_namespaces, source: :search, class_name: 'Discerner::Search'
end
