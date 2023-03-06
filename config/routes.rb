Rails.application.routes.draw do
  root "health#check"

  get "health/check", to: 'health#check'
  get "health/invalid", to: 'health#invalid'
  get "health/not_found", to: 'health#not_found'

  namespace :v1, defaults: {format: :json} do
    resources :sample, only: %i{create} do
      delete "/",on: :collection, to: 'sample#destroy'
    end

    get "/common/identity_documents", to: 'common#identity_documents'
  end

end
