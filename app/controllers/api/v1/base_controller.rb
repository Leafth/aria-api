module Api
  module V1
    class BaseController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
      rescue_from ArgumentError, with: :handle_invalid_enum

      private

      def render_not_found(error)
        render json: { error: error.message }, status: :not_found
      end

      def render_unprocessable_entity(error)
        render json: {
          error: "Validation failed",
          details: error.record.errors.to_hash
        }, status: :unprocessable_entity
      end

      def handle_invalid_enum(error)
        if error.message.include?("is not a valid")
          render json: { errors: { phase: [ "is not valid" ] } }, status: :unprocessable_entity
        else
          raise error
        end
      end
    end
  end
end
