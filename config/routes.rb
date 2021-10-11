Rails.application.routes.draw do

  resources :visitors, only: [:index] do
    get :mail_test, on: :collection
  end
  resources :providers

  resources :vls do
    collection do
      get :import
      get :linking
      get :syncronaize
      get :import_linking_syncronaize
      get :unlinking_to_xls
    end
  end

  resources :ashantis do
    collection do
      get :import
      get :linking
      get :syncronaize
      get :import_linking_syncronaize
      get :unlinking_to_xls
    end
  end

  resources :mbs do
    collection do
      get :import
      get :linking
      get :syncronaize
      get :import_linking_syncronaize
      get :unlinking_to_xls
    end
  end

  resources :products do
    collection do
      get :create_csv
      get :edit_multiple
      put :update_multiple
      post :delete_selected
      post :import
      get :import_insales_xml
      get :update_price_quantity_all_providers
      get :csv_param
    end
  end

  root to: 'providers#index'
  devise_for :users, :controllers => {:registrations => "registrations"}
  resources :users

  mount ActionCable.server => '/cable'
end
