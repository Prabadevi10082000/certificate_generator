require 'openssl'

module CertificateGenerator
  def self.generate_ca
    # Similar to the previous examples
  end

  def self.generate_signed_certificate(ca_key, ca_cert, common_name)
    # Similar to the previous examples
  end

  def self.get_certificate_expiration_date(ca_cert, server_cert)
    # Implement logic to get expiration date from the certificates
  end
end