Rails.application.routes.draw do
  <%= 'mount Discerner::Engine => "/"' if defined?(Discerner) %>
end