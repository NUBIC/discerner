class ReplaceNamespaceColumnsWithLabelForSearches < ActiveRecord::Migration
  def up
    add_column :discerner_searches, :label, :string

    Discerner::Search.transaction do
      Discerner::Search.all.each do |search|
        if !search.namespace_id.blank?
          search.search_namespaces << Discerner::SearchNamespace.create(namespace_type: search.namespace_type, namespace_id: search.namespace_id)
        elsif !search.namespace_type.blank?
          search.label = search.namespace_type
        end
        search.save!
      end
      remove_column :discerner_searches, :namespace_type
      remove_column :discerner_searches, :namespace_id
    end
  end

  def down
    add_column :discerner_searches, :namespace_id, :integer
    add_column :discerner_searches, :namespace_type, :string

    Discerner::Search.transaction do
      Discerner::Search.all.each do |search|
        if search.search_namespaces.any?
          search.namespace_id = search.search_namespaces.first.namespace_id
          search.namespace_type = search.search_namespaces.first.namespace_type
        elsif !search.label.blank?
          search.namespace_type = search.label
        end
        search.save!
      end
    end

    remove_column :discerner_searches, :label
  end
end
