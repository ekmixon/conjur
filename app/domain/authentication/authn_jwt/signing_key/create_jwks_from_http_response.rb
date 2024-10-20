module Authentication
  module AuthnJwt
    module SigningKey
      # CreateJwksFromHttpResponse command class is responsible to create jwks object from http response
      CreateJwksFromHttpResponse ||= CommandClass.new(
        dependencies: {
          logger: Rails.logger,
          jwk_set_class: JSON::JWK::Set
        },
        inputs: %i[http_response]
      ) do
        def call
          validate_response_exists
          validate_response_has_a_body
          create_jwks_from_http_response
        end

        private

        def validate_response_exists
          raise Errors::Authentication::AuthnJwt::MissingHttpResponse if @http_response.blank?
        end

        def validate_response_has_a_body
          raise Errors::Authentication::AuthnJwt::InvalidHttpResponseFormat unless @http_response.respond_to?(:body)
        end

        def create_jwks_from_http_response
          @logger.debug(LogMessages::Authentication::AuthnJwt::CreatingJwksFromHttpResponse.new)
          parse_jwks_response
        end

        def encoded_body
          @encoded_body ||= Base64.encode64(response_body)
        end

        def response_body
          @response_body ||= @http_response.body
        end

        def parse_jwks_response
          begin
            parsed_response = JSON.parse(response_body)
            keys = parsed_response['keys']
          rescue => e
            raise Errors::Authentication::AuthnJwt::FailedToConvertResponseToJwks.new(
              encoded_body,
              e.inspect
            )
          end

          validate_keys_not_empty(keys, encoded_body)
          @logger.debug(LogMessages::Authentication::AuthnJwt::CreatedJwks.new)
          { keys: @jwk_set_class.new(keys) }
        end

        def validate_keys_not_empty(keys, encoded_body)
          raise Errors::Authentication::AuthnJwt::FetchJwksUriKeysNotFound, encoded_body if keys.blank?
        end
      end
    end
  end
end
