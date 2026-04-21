module Api
  module V1
    class UsersController < BaseController
      include CurrentTenant
      include AuthenticateRequest

      def me
        render json: {
          id: current_user.id,
          email: current_user.email,
          name: current_user.name
        }
      end
    end
  end
end
