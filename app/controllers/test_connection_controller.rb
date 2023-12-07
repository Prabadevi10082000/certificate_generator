require 'openssl'
require 'net/http'

class TestConnectionController < ApplicationController
  def verify_ssl_expiration
    ca_cert_path = Rails.root.join('ca_cert.pem')
    api_url = 'http://localhost:3000/api/ssl_expiration' # Update with your actual API URL

    @result = verify_certificate_expiration(ca_cert_path, api_url)
    render :result
  end

  private

  def verify_certificate_expiration(ca_cert_path, api_url)
    uri = URI.parse(api_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.ca_file = ca_cert_path

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    JSON.parse(response.body)['expiration_date']
  end
end
