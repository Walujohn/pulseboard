Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :status_updates, only: [ :index, :show, :create, :update, :destroy ] do
        resources :comments, only: [ :index, :create ]
        resources :reactions, only: [ :index, :create, :destroy ]
        member do
          get :timeline
        end
      end
    end
  end

  resources :status_updates, only: [ :index, :show, :create, :edit, :update, :destroy ] do
    post :like, on: :member
    resources :comments, only: [ :create, :destroy ]
  end

  root "status_updates#index"
end
