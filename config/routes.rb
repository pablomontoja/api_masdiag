Rails.application.routes.draw do
  root "health#check"

  get "health/check", to: 'health#check'
  get "health/invalid", to: 'health#invalid'
  get "health/not_found", to: 'health#not_found'

  namespace :v1, defaults: {format: :json} do
    resources :sample, only: %i{create} do
      delete "/delete/:code",on: :collection, to: 'sample#destroy'
    end

    # resources :result do
    get "/result/get/:code", to: 'result#show'
    # end

    get "/common/identity_documents", to: 'common#identity_documents'
    get "/common/version", to: 'common#version'

    post "/setup/set_result_post_endpoint_url", to: 'setup#set_result_post_endpoint_url'
    post "/trigger/send_result/:code", to: 'trigger#send_result'
  end

  namespace :nume, defaults: {format: :json} do
    resources :sample, only: %i{create} do
      delete "/delete/:code",on: :collection, to: 'sample#destroy'
    end

    # resources :result do
    get "/result/get/:code", to: 'result#show'
    # end

    get "/common/identity_documents", to: 'common#identity_documents'
    get "/common/version", to: 'common#version'

    post "/setup/set_result_post_endpoint_url", to: 'setup#set_result_post_endpoint_url'
    post "/trigger/send_result/:code", to: 'trigger#send_result'
  end

  # get '*path' => redirect('/')

end
