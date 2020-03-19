Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
  get 'password_resets/new'
  get 'password_resets/edit'
  get 'sessions/new'
  get 'signup', to: 'users#new'
  post 'signup', to: 'users#create'
  get '/login', to: 'sessions#new'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy' 
  resources :account_activations, only: [:edit]
  resources :users
  resources :password_resets, only: [:new, :create, :edit, :update]
  resources :gigs do
    resource :proposals, except: :index
    collection do
      get :search
    end
    resources :solutions, only: [:index, :destroy]
  end
  resources :proposals do
    resources :solutions, only: [:create]
  end
  
  root to: 'home#index'
  get '/mygigs', to: 'gigs#mygigs'
  get '/myproposals', to: 'proposals#myproposals'
  get '/my_solutions', to: 'solutions#my_solutions'

  resources :users do
    member do
      post :deactivate
      post :activate
    end

    resources :conversations do
      member do
        post :mark_as_read
      end
      resources :messages
    end

    resources :notifications do
      member do
        post :mark_as_read
      end
    end
  end


  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
