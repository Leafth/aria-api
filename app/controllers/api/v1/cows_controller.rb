module Api
  module V1
    class CowsController < BaseController
      include CurrentTenant
      include AuthenticateRequest

      def create
        cow = current_tenant.cows.new(cow_params)

        if cow.save
          render json: cow, status: :created
        else
          render json: { errors: cow.errors }, status: :unprocessable_entity
        end
      end

      private

      def cow_params
        params.require(:cow).permit(
          :name,
          :ear_tag,
          :birth_date,
          :breed,
          :weight,
          :phase,
          :active
        )
      end
    end
  end
end
