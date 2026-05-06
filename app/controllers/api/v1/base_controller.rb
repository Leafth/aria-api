module Api
  module V1
    class BaseController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
      rescue_from Auth::Error, with: :render_auth_error

      rescue_from ArgumentError, with: :handle_invalid_enum

      private

      def render_not_found(error)
        render json: { errors: { resource: [ error.message ] } }, status: :not_found
      end

      def render_unprocessable_entity(error)
        render json: { errors: error.record.errors }, status: :unprocessable_entity
      end

      def bad_request(error)
        render json: { errors: { base: [ error.message ] } }, status: :bad_request
      end

      def render_auth_error(error)
        render json: { errors: { base: [ error.message ] } }, status: :unauthorized
      end

      def handle_invalid_enum(error)
        if error.message.include?("is not a valid")
          render json: { errors: { phase: [ "Invalid value" ] } }, status: :unprocessable_entity
        else
          raise error
        end
      end
    end
  end
end
