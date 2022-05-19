Rails.application.routes.draw do
  resources :books
  resources :users, except:[:new]

  root 'courses#index'
  get 'login', to:'sessions#new'
  post 'login', to:'sessions#create', as: :login_path
  delete 'logout', to:'sessions#destroy'

  get 'signup', to: 'users#new'
  post 'signup', to: 'users#create'

  get 'search', to: 'books#search'
  get 'books_search', to: 'books#books_search'

  post 'rent_book', to: 'userbooks#rent'
  post 'unrent_book', to: 'userbooks#unrent'

end
