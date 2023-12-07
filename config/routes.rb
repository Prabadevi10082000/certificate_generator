
Rails.application.routes.draw do
  get '/', to: 'certificate_generator#index'
  post '/create_certificate', to: 'certificate_generator#create_certificate'
  get '/result', to: 'certificate_generator#result'

  namespace :api do
    get '/ssl_expiration', to: 'ssl_api#expiration'
  end

  get '/test_connection/verify_ssl_expiration', to: 'test_connection#verify_ssl_expiration'
  get '/view_certificates', to: 'certificate_generator#view_certificates'
end