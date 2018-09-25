Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: "pages#import"

  controller :pages do
    get 'import' => :import
    get 'subscription' => :subscription
    get 'log' => :log
    get 'users' => :users
  end

  controller :processes do
    post 'import' => :import
  end

  match 'download', to: 'processes#download', as: 'download', via: :get

end