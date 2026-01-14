Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :status_updates, only: [ :index, :show, :create, :update, :destroy ]
    end
  end

  resources :status_updates, only: [ :index, :create, :edit, :update, :destroy ] do
    post :like, on: :member
  end

  root "status_updates#index"
end
