module Api
  module V1
    class SummaryController < BaseController
      include CurrentTenant
      include AuthenticateRequest

      def show
        render json: ::Dashboard::SummaryService.new(
          tenant: current_tenant
        ).call
      end
    end
  end
end
