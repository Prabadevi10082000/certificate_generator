require 'openssl'

module CertificateGenerator
  def self.generate_ca
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

  def self.generate_signed_certificate(ca_key, ca_cert, common_name)
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

  def self.get_certificate_expiration_date(ca_cert, server_cert)
    server_x509 = OpenSSL::X509::Certificate.new(server_cert)
    expiration_date = server_x509.not_after

    expiration_date.strftime('%Y-%m-%d %H:%M:%S %Z')
  end
end