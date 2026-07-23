Rails.application.routes.draw do
  root "health#check"

  #########################################################
  ### WEBHOOK (machine-to-machine, Bearer token auth)
  #########################################################
  namespace :webhook do
    resources :scanned_docs, only: [:create]
  end

  get "health/check", to: 'health#check'
  get "health/invalid", to: 'health#invalid'
  get "health/not_found", to: 'health#not_found'

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  # get "up" => "rails/health#show", as: :rails_health_check

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
      put "/update", on: :collection, to: 'sample#update'
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
    post "/trigger/send_result/:code", to: 'trigger#send_result'
    post "/kits/qns", to: 'kit#qns'
    get "/kits/is_uniq/:code", to: 'kit#is_uniq'
    post "/kits/declare", to: 'kit#declare'
    post "/kits/declare/generic", to: 'kit#declare_generic'
    delete "/kits/remove/declared/:code", to: 'kit#destroy_declared'
    post "/kits/assign_tests", to: 'kit#assign_tests'
    get "/kits/check_code/:code", to: 'kit#check_code'
  end


  #########################################################
  ### TOXO
  #########################################################
  namespace :toxo, defaults: { format: :json } do
    namespace :samples do
      resources :registrations, only: %i[new create]
      resources :exports, only: %i[index]
      resources :on_request_measurements, only: %i[create]
    end

    namespace :measurements do
      resources :exports, only: %i[index]
    end

    resources :samples, only: %i[index show destroy]

    resources :patients,              only: %i[index show]
    resources :projects,              only: %i[index]
    resources :reserved_sample_codes, only: %i[index show]
    resources :measurements,          only: %i[index show]
    get "dashboard", to: "dashboard#index"
  end


  #########################################################
  ### MASDIAG
  #########################################################
  namespace :masdiag, defaults: {format: :json} do
    post "/setup/result_post_endpoint", to: 'setup#result_post_endpoint'

    post "/notifications/trigger", to: 'notification#trigger'
    post "/notifications/sample_status_changed/:sample_id", to: 'notification#sample_status_changed'

    # Ujednolicone endpointy zdarzeń powiadomień (LabSample) — wybór szablonu
    # (laboratoryjny vs Toxo) po stronie tej aplikacji.
    post "sample_accepted",       to: "notifications#sample_accepted"
    post "sample_rejected",       to: "notifications#sample_rejected"
    post "result_available",      to: "notifications#result_available"
    post "registration_reminder", to: "notifications#registration_reminder"

    # storage app
    post "stock_room/stock_out_by_packages", to: "stock_rooms#stock_out_by_packages"
    post "stock_room/stock_out_by_shipment", to: "stock_rooms#stock_out_by_shipment"
    post "stock_room/back_to_stock_by_shipment/:shipment_id", to: "stock_rooms#back_to_stock_by_shipment"
    get "stock_room/is_package_in_stock/:id", to: "stock_rooms#is_package_in_stock" 
  end


  #########################################################
  ### MASDIAG MAILER
  #########################################################
  namespace :masdiag_mailer, defaults: {format: :json} do
    get "send_all_mails", to: 'emails#send_all'
    
    # Samples    
    post "send_acceptance_notifications", to: 'emails#send_acceptance_notifications'
    post "send_cancellation_notifications", to: 'emails#send_cancellation_notifications'
    post "send_error_notifications", to: 'emails#send_error_notifications'
    post 'send_notification_after_delayed_reg', to: 'emails#send_notification_after_delayed_reg'
    post 'after_sample_registration', to: 'emails#after_sample_registration'

    # shop_orders
    post 'after_new_order_save', to: 'emails#after_new_order_save'
    post 'shipping_after_new_order', to: 'emails#shipping_after_new_order'

    # www.masdiag.pl contact form
    post 'masdiag_website_contact_form', to: 'emails#masdiag_website_contact_form'
  end


  #########################################################
  ### LALEN
  #########################################################
  # namespace :lalen, defaults: {format: :json} do
  #   resources :sample, only: %i{create} do
  #     delete "/delete/:code",on: :collection, to: 'sample#destroy'
  #   end

  #   # get "/result/get/:code", to: 'result#show'
  #   # post "/kits/assign_tests", to: 'kit#assign_tests'
  # end


  #########################################################
  ### PATIENT_PORTAL
  #########################################################
  namespace :patient_portal, defaults: { format: :json } do
    resources :results, only: :index
    resources :samples, only: :index
  end

  
  
  #########################################################
  ### REGSPEC
  #########################################################
  namespace :regspec, defaults: { format: :json } do
    resources :institutions, only: %i{ create update }
    resources :contractors, only: %i{ create update }
    resources :samples, only: %i{ create update }
    resources :patients, only: %i{ update }
  end

  #########################################################
  ### DiagnostykaPrecyzyjna
  #########################################################
  namespace :diagnostyka_precyzyjna, defaults: { format: :json } do
    post :shop_orders, to: 'shop_orders#import'
  end



  mount MissionControl::Jobs::Engine, at: "/jobs"

  # get '*path' => redirect('/')

end
