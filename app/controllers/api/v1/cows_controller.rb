module Api
  module V1
    class CowsController < BaseController
      include CurrentTenant
      include AuthenticateRequest

      before_action :set_cow, only: [ :show, :update, :destroy ]

      def index
        cows = current_tenant.cows

        cows = apply_filters(cows)
        cows = apply_search(cows)
        cows = apply_sort(cows)
        cows = paginate(cows)

        render_paginated cows, serializer: CowSerializer
      end

      def show
        render json: @cow, serializer: CowProfileSerializer, status: :ok
      end

      def create
        cow = Cows::Create.new(
          tenant: current_tenant,
          params: cow_params
        ).call

        render json: cow, serializer: CowSerializer, status: :created
      end

      def update
        if forbidden_params_present?
          return render json: {
            errors: { forbidden_fields: [ I18n.t!("cows.errors.forbidden_fields") ] }
          }, status: :unprocessable_entity
        end

        @cow.update!(update_cow_params)

        render json: @cow, serializer: CowSerializer, status: :ok
      end

      def destroy
        @cow.destroy!
        head :no_content
      end

      private

      def set_cow
        @cow = current_tenant.cows.find(params[:id])
      end

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

      def update_cow_params
        params.require(:cow).permit(
          :name,
          :ear_tag,
          :birth_date,
          :breed
        )
      end

      def apply_filters(scope)
        scope = scope.where("birth_date >= ?", params[:birth_from]) if params[:birth_from].present?
        scope = scope.where("birth_date <= ?", params[:birth_to]) if params[:birth_to].present?
        scope = scope.where("weight >= ?", params[:weight_from]) if params[:weight_from].present?
        scope = scope.where("weight <= ?", params[:weight_to]) if params[:weight_to].present?
        scope = scope.where(phase: params[:phase]) if params[:phase].present?
        scope = scope.where(reproductive_status: params[:reproductive_status]) if params[:reproductive_status].present?
        scope = scope.where(active: params[:active]) if params[:active].present?
        scope = scope.where("created_at >= ?", params[:created_from]) if params[:created_from].present?
        scope = scope.where("created_at <= ?", params[:created_to]) if params[:created_to].present?

        scope
      end

      def apply_search(scope)
        return scope if params[:q].blank?

        scope.where(
          "LOWER(cows.name) LIKE :q OR LOWER(cows.breed) LIKE :q OR LOWER(cows.ear_tag) LIKE :q",
          q: "%#{params[:q].downcase}%"
        )
      end

      def apply_sort(scope)
        sort_by = params[:sort_by].presence || "updated_at"
        sort_dir = params[:sort_dir] == "asc" ? :asc : :desc

        allowed_fields = %w[name ear_tag breed phase birth_date weight created_at updated_at]

        return scope.order(created_at: :desc) unless allowed_fields.include?(sort_by)

        scope.order(sort_by => sort_dir)
      end

      def paginate(scope)
        page = params[:page].to_i > 0 ? params[:page].to_i : 1
        per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 10

        scope.page(page).per(per_page)
      end

      def forbidden_params_present?
        return false unless params[:cow]

        permitted = update_cow_params.keys.map(&:to_s)
        incoming  = params[:cow].keys

        (incoming - permitted).any?
      end
    end
  end
end
