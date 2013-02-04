Discerner::Engine.routes.draw do
  resources :searches do
    member do
      get :rename
      get :export
    end
  end
  resources :parameters
end
