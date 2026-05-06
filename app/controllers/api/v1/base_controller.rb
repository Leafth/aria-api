module Api
  module V1
    class BaseController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
      rescue_from ActionDispatch::Http::Parameters::ParseError, with: :bad_request
      rescue_from Auth::Error, with: :render_auth_error

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
    end
  end
end
