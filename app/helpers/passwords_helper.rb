module PasswordsHelper
    def raw_secret_url(password)
        # Support forced https links with FORCE_SSL env var
        secret_url = if ENV.key?('FORCE_SSL') && !request.ssl?
            password_url(password).gsub(/http/i, 'https')
        else
            password_url(password)
        end

        secret_url
    end
    def secret_url(password)
        url = raw_secret_url(password)
        url += '/r' if password.retrieval_step
        url
    end
end
