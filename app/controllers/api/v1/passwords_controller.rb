module Api
  module V1
    class PasswordsController < BaseController
      include CurrentTenant

      def create
        user = current_tenant.users.find_by(email: params[:email].to_s.downcase)

        user&.send_reset_password_instructions

        render json: { message: I18n.t!("devise.passwords.send_instructions") }, status: :ok
      end

      def update
        user = current_tenant.users.reset_password_by_token(reset_params)

        if user.errors.empty?
          render json: { message: I18n.t("devise.passwords.updated_not_active") }, status: :ok
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_content
        end
      end

      private

      def reset_params
        params.permit(:reset_password_token, :password, :password_confirmation)
      end
    end
  end
end
