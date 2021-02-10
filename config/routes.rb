Rails.application.routes.draw do

  resources :mbs do
    collection do
      get :import
      get :syncronaize
    end
  end

  resources :providers

  resources :products do
    collection do
      get :create_csv
      get :edit_multiple
      put :update_multiple
      post :delete_selected
      post :import
      get :csv_param
    end
  end
  root to: 'providers#index'
  devise_for :users, :controllers => {:registrations => "registrations"}
  resources :users
end
