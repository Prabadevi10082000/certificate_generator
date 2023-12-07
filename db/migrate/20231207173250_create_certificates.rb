class CreateCertificates < ActiveRecord::Migration[6.1]
  def change
    create_table :certificates do |t|
        t.string :common_name
        t.text :ca_cert
        t.text :server_cert
        t.string :expiration_date
        t.timestamps
    end
  end
end
