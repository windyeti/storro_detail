Rails.application.routes.draw do
  resources :products do
    collection do
      get :get_file
      get :load_by_api
      get :edit_multiple
      put :update_multiple
      post :delete_selected
      get :csv_param
      get :set_cattitle
    end
  end
  root to: 'visitors#index'
  devise_for :users
  resources :users
end
