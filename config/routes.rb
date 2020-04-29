Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web, at: '/sidekiq'
  
  resources :chats
  root 'chats#new'
end
