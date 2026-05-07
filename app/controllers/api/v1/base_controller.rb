module Api
  module V1
    class BaseController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
      rescue_from ActiveRecord::RecordNotDestroyed, with: :render_record_not_destroyed
      rescue_from ActionDispatch::Http::Parameters::ParseError, with: :bad_request
      rescue_from ActionController::ParameterMissing, with: :bad_request
      rescue_from Auth::Error, with: :render_auth_error

      private

      def render_paginated(collection, serializer:, status: :ok)
        render json: {
          data: ActiveModelSerializers::SerializableResource.new(
            collection,
            each_serializer: serializer
          ),
          meta: pagination_meta(collection)
        }, status: status
      end

      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          next_page: collection.next_page,
          prev_page: collection.prev_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count
        }
      end

      def render_not_found(error)
        render json: { errors: { resource: [ error.message ] } }, status: :not_found
      end

      def render_unprocessable_entity(error)
        render json: { errors: error.record.errors.to_hash(true) }, status: :unprocessable_entity
      end

      def render_record_not_destroyed(error)
        render json: { errors: error.record.errors.to_hash(true) }, status: :unprocessable_entity
      end

      def bad_request(error)
        render json: { errors: { base: [ error.message.capitalize  ] } }, status: :bad_request
      end

      def render_auth_error(error)
        render json: { errors: { base: [ error.message ] } }, status: :unauthorized
      end
    end
  end
end
