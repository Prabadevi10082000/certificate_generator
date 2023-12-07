require 'openssl'

class CertificateGeneratorController < ApplicationController
  def index
    render 'certificate_generator/generate_certificate_form'
  end

  def create_certificate
    common_name = params[:common_name] || 'localhost'
    ca_key, ca_cert = generate_ca
    server_key, server_cert = generate_signed_certificate(ca_key, ca_cert, common_name)

    # Save the generated server certificate to a file
    File.write("server_key_#{common_name}.pem", server_key.to_pem)
    File.write("server_cert_#{common_name}.pem", server_cert.to_pem)

    # Pass common_name to the view
    @common_name = common_name

    # Render the success view
    view_certificates
  end

  private

  def generate_ca
    key = OpenSSL::PKey::RSA.new(2048)
    cert = OpenSSL::X509::Certificate.new

    cert.version = 2
    cert.serial = 1
    cert.subject = cert.issuer = OpenSSL::X509::Name.parse('/C=US/ST=CA/L=San Francisco/O=MyCA/CN=MyCA Root Certificate')
    cert.public_key = key.public_key
    cert.not_before = Time.now
    cert.not_after = cert.not_before + 365 * 24 * 60 * 60 # 1 year validity

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = cert

    cert.add_extension(ef.create_extension('basicConstraints', 'CA:TRUE', true))
    cert.add_extension(ef.create_extension('keyUsage', 'keyCertSign, cRLSign', true))
    cert.add_extension(ef.create_extension('subjectKeyIdentifier', 'hash', false))

    cert.sign(key, OpenSSL::Digest::SHA256.new)

    [key, cert]
  end

  def generate_signed_certificate(ca_key, ca_cert, common_name)
    key = OpenSSL::PKey::RSA.new(2048)
    cert = OpenSSL::X509::Certificate.new

    cert.version = 2
    cert.serial = 2
    cert.subject = OpenSSL::X509::Name.parse("/C=US/ST=CA/L=San Francisco/O=MyOrganization/CN=#{common_name}")
    cert.issuer = ca_cert.subject
    cert.public_key = key.public_key
    cert.not_before = Time.now
    cert.not_after = cert.not_before + 365 * 24 * 60 * 60 # 1 year validity

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = ca_cert

    cert.add_extension(ef.create_extension('subjectKeyIdentifier', 'hash', false))
    cert.add_extension(ef.create_extension('authorityKeyIdentifier', 'keyid:always', false))
    cert.add_extension(ef.create_extension('keyUsage', 'keyEncipherment, dataEncipherment', true))
    cert.add_extension(ef.create_extension('extendedKeyUsage', 'serverAuth', false))

    cert.sign(ca_key, OpenSSL::Digest::SHA256.new)

    [key, cert]
  end

  def view_certificates
    @ca_cert_content = File.read('ca_cert.pem') rescue 'CA Certificate not found'
    @server_cert_content = File.read('server_cert.pem') rescue 'Server Certificate not found'
    @expiration_date = expiration_date
    render 'certificate_generator/view_certificates'
  end


  def expiration_date
    common_name = params[:common_name]
    ca_cert = request.env['HTTP_CA_CERTIFICATE']

    certificate = Certificate.find_by_common_name(common_name)

    if certificate
      expiration_date = CertificateGenerator.get_certificate_expiration_date(ca_cert, certificate.server_cert)
      { success: true, expiration_date: expiration_date }.to_json
    else
      { success: false, error: 'Certificate not found.' }.to_json
    end
  end
end