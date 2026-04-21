module Api
  module V1
    class AuthController < BaseController
      include CurrentTenant

      rescue_from Auth::Login::Error, with: :render_auth_error

      def login
        result = Auth::Login.new(
          tenant: current_tenant,
          email: login_params[:email],
          password: login_params[:password],
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        ).call

        set_auth_cookies(result)

        render json: {
          access_token: result[:access_token],
          refresh_token: result[:refresh_token],
          token_type: "Bearer",
          expires_in: Rails.configuration.x.auth.access_token_expiration.to_i,
          user: user_payload(result[:user])
        }, status: :ok
      end

      def refresh
        token = cookies[:refresh_token] || params.dig(:auth, :refresh_token)

        result = Auth::Refresh.new(
          tenant: current_tenant,
          refresh_token: token
        ).call

        set_auth_cookies(result)

        render json: {
          access_token: result[:access_token],
          refresh_token: result[:refresh_token],
          token_type: "Bearer",
          expires_in: Rails.configuration.x.auth.access_token_expiration.to_i,
          user: user_payload(result[:user])
        }, status: :ok
      end

      private

      def login_params
        params.require(:auth).permit(:email, :password)
      end

      def user_payload(user)
        {
          id: user.id,
          name: user.name,
          email: user.email,
          tenant_id: user.tenant_id
        }
      end

      def set_auth_cookies(result)
        response.set_cookie(
          :refresh_token,
          value: result[:refresh_token],
          httponly: true,
          secure: Rails.env.production?,
          same_site: :strict,
          expires: Rails.configuration.x.auth.refresh_token_expiration.from_now
        )

        response.set_cookie(
          :access_token,
          value: result[:access_token],
          httponly: true,
          secure: Rails.env.production?,
          same_site: :lax,
          expires: Rails.configuration.x.auth.access_token_expiration.from_now
        )
      end

      def clear_auth_cookies
        cookies.delete(:refresh_token)
        cookies.delete(:access_token)
      end

      def render_auth_error(error)
        render json: { error: error.message }, status: :unauthorized
      end
    end
  end
end
