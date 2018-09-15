Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: "pages#import"

  controller :pages do
    get 'import' => :import
    get 'subscription' => :subscription
    get 'log' => :log
    get 'users' => :users
  end

end