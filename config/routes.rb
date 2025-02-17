Rails.application.routes.draw do
  devise_for :users, controllers: {sessions: "sessions"}
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: "pages#import"

  controller :gifts do
    post 'gift-email' => :gift_email
    get 'view-pdf' => :view_pdf
  end

  controller :pages do
    get 'import' => :import
    get 'subscriptions' => :subscription
    get 'subscription_page' => :subscription_page
    get 'log' => :log
    get 'users' => :users
  end

  controller :processes do
    post 'import' => :import
    post 'single' => :single
    post 'single-from-online-store' => :single_from_online_store
    post 'edit' => :edit
    post 'retry' => :retry
    post 'delete' => :delete
    post 'user' => :add_user
    post 'edit-user' => :edit_user
    post 'delete-user' => :delete_user
    post 'recharge-delete-subscription' => :recharge_delete_subscription
    post 'recharge-delete-customer' => :recharge_delete_customer
    post 'stripe-delete' => :stripe_delete
    post 'stripe-failed' => :stripe_failed
  end

  match 'download', to: 'processes#download', as: 'download', via: :get

end