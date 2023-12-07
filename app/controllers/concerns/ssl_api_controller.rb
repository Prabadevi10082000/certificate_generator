require 'openssl'

class SslApiController < ApplicationController
  def expiration
    @expiration_date = ssl_certificate_expiration_date
    render json: { expiration_date: @expiration_date }
  end

  private

  def ssl_certificate_expiration_date
    cert_path = Rails.root.join('server_cert.pem')
    cert = OpenSSL::X509::Certificate.new(File.read(cert_path))
    cert.not_after
  end
end