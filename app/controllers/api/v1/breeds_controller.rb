module Api
  module V1
    class BreedsController < BaseController
      include CurrentTenant
      include AuthenticateRequest

      def index
        breeds = current_tenant.breeds.order(:name)

        render json: breeds, each_serializer: BreedSerializer, status: :ok
      end
    end
  end
end
