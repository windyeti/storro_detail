Rails.application.routes.draw do

  resources :providers

  resources :products do
    collection do
      get :edit_multiple
      put :update_multiple
      post :delete_selected
      post :import
      get :csv_param
    end
  end
  root to: 'providers#index'
  devise_for :users
  resources :users
end
