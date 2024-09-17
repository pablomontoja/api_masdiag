Rails.application.routes.draw do
  root "health#check"

  get "health/check", to: 'health#check'
  get "health/invalid", to: 'health#invalid'
  get "health/not_found", to: 'health#not_found'


  #########################################################
  ### POLISH
  #########################################################
  namespace :v1, defaults: {format: :json} do
    resources :sample, only: %i{create} do
      delete "/delete/:code",on: :collection, to: 'sample#destroy'
    end

    # resources :result do
    get "/result/get/:code", to: 'result#show'
    # end

    get "/common/identity_documents", to: 'common#identity_documents'
    get "/common/api_version", to: 'common#api_version'
    get "/common/tests", to: 'common#tests'

    post "/setup/set_result_post_endpoint_url", to: 'setup#result_post_endpoint'
    post "/setup/result_post_endpoint", to: 'setup#result_post_endpoint'
    post "/trigger/send_result/:code", to: 'trigger#send_result'

    post "/kits/assign_tests", to: 'kit#assign_tests'
    get "/kits/check_code/:code", to: 'kit#check_code'

    get "/institution/pool_status", to: 'institution#pool_status'
  end

  #########################################################
  ###     FOREIGN
  #########################################################
  namespace :fv1, defaults: {format: :json} do
    resources :sample, only: %i{create} do
      delete "/delete/:code",on: :collection, to: 'sample#destroy'
      post "/activate_confirmation_test/:code", on: :collection, to: 'sample#activate_confirmation_test'
    end

    # resources :result do
    get "/result/get/:code", to: 'result#show'
    # end

    get "/common/identity_documents", to: 'common#identity_documents'
    get "/common/api_version", to: 'common#api_version'
    get "/common/tests", to: 'common#tests'

    post "/setup/set_result_post_endpoint_url", to: 'setup#result_post_endpoint'
    post "/setup/result_post_endpoint", to: 'setup#result_post_endpoint'
    post "/trigger/send_result/:code", to: 'trigger#send_result'

    post "/kits/assign_tests", to: 'kit#assign_tests'
    get "/kits/check_code/:code", to: 'kit#check_code'
  end

  namespace :nume, defaults: {format: :json} do
    resources :sample, only: %i{create} do
      delete "/delete/:code",on: :collection, to: 'sample#destroy'
      post "/activate_confirmation_test/:code", on: :collection, to: 'sample#activate_confirmation_test'
    end

    # resources :result do
    get "/result/get/:code", to: 'result#show'
    # end

    get "/common/identity_documents", to: 'common#identity_documents'
    get "/common/api_version", to: 'common#api_version'
    get "/common/tests", to: 'common#tests'

    post "/setup/set_result_post_endpoint_url", to: 'setup#result_post_endpoint'
    post "/setup/result_post_endpoint", to: 'setup#result_post_endpoint'
    post "/trigger/send_result/:code", to: 'trigger#send_result'

    post "/kits/assign_tests", to: 'kit#assign_tests'
    get "/kits/check_code/:code", to: 'kit#check_code'
  end

  namespace :lalen, defaults: {format: :json} do
    resources :sample, only: %i{create} do
      delete "/delete/:code",on: :collection, to: 'sample#destroy'
      # post "/activate_confirmation_test/:code", on: :collection, to: 'sample#activate_confirmation_test'
    end

    # resources :result do
    # get "/result/get/:code", to: 'result#show'
    # end

    # get "/common/identity_documents", to: 'common#identity_documents'
    # get "/common/api_version", to: 'common#api_version'
    # get "/common/tests", to: 'common#tests'

    # post "/setup/set_result_post_endpoint_url", to: 'setup#result_post_endpoint'
    # post "/setup/result_post_endpoint", to: 'setup#result_post_endpoint'
    # post "/trigger/send_result/:code", to: 'trigger#send_result'

    post "/kits/declare", to: 'kit#declare'
    post "/kits/declare/generic", to: 'kit#declare_generic'
    delete "/kits/remove/declared/:code", to: 'kit#destroy_declared'
    post "/kits/assign_tests", to: 'kit#assign_tests'
    get "/kits/check_code/:code", to: 'kit#check_code'
  end


  #########################################################
  ### MASDIAG
  #########################################################
  namespace :masdiag, defaults: {format: :json} do
    post "/setup/result_post_endpoint", to: 'setup#result_post_endpoint'
    
    post "/notifications/trigger", to: 'notification#trigger'
    post "/notifications/sample_status_changed/:sample_id", to: 'notification#sample_status_changed'
  end

  #########################################################
  ### LALEN
  #########################################################
  namespace :lalen, defaults: {format: :json} do
    resources :sample, only: %i{create} do
      delete "/delete/:code",on: :collection, to: 'sample#destroy'
    end

    # get "/result/get/:code", to: 'result#show'
    # post "/kits/assign_tests", to: 'kit#assign_tests'
  end


  #########################################################
  ### PATIENT_PORTAL
  #########################################################
  namespace :patient_portal, defaults: {format: :json} do
    resources :results, only: :index
    resources :samples, only: :index
  end

  # get '*path' => redirect('/')

end
