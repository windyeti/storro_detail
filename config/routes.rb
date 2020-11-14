Rails.application.routes.draw do

  resources :products do
    collection do
      get :edit_multiple
      put :update_multiple
      post :delete_selected
    end
  end
  root to: 'visitors#index'
  devise_for :users
  resources :users
end
