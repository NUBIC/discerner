Discerner::Engine.routes.draw do
  resources :searches do
    member do
      get :rename
      resources :export_parameters, :only => :index do
        collection do
          post :assign
        end
      end
    end
  end
  resources :parameters
end
