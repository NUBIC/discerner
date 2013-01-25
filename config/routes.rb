Discerner::Engine.routes.draw do
  root :to => "searches#new"
  resources :searches do
    member do
      get :rename
      get :export
    end
  end
  resources :parameters
end
