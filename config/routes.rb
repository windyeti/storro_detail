Rails.application.routes.draw do

  resources :visitors, only: [:index]
  resources :providers

  resources :mbs do
    collection do
      get :import
      get :linking
      get :syncronaize
      get :import_linking_syncronaize
    end
  end

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
