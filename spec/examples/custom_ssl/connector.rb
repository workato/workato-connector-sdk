# typed: false
# frozen_string_literal: true

{
  title: 'Disable SSL',

  # HTTP basic auth example.
  connection: {
    fields: [
      {
        name: '__disable_tls_server_cert_verification',
        type: 'boolean',
        control_type: 'checkbox',
        label: 'Disable SSL verification'
      },
      {
        name: 'client_cert'
      },
      {
        name: 'client_key'
      },
      {
        name: 'client_intermediate_cert'
      },
      {
        name: 'custom_server_cert'
      }
    ],

    authorization: {
      apply: lambda do |connection|
        if connection['client_cert'].present?
          tls_client_cert(
            certificate: connection['client_cert'],
            key: connection['client_key'],
            intermediates: connection['client_intermediate_cert']
          )
        end
        if connection['custom_server_cert']
          tls_server_certs(certificates: connection['custom_server_cert'])
        end
      end
    }
  },

  test: lambda { |_connection|
    true
  },

  actions: {
    posts: {
      execute: lambda {
        {
          posts: get('https://localhost:9123/posts')
        }
      }
    },
    posts_weak: {
      execute: lambda { |connection|
        {
          posts: get('https://localhost:9123/posts').tls_server_certs(
            certificates: connection['custom_server_cert'],
            strict: false
          )
        }
      }
    }
  }
}
