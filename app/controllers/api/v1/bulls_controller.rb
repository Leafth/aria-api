module Api
  module V1
    class BullsController < BaseController
      include CurrentTenant
      include AuthenticateRequest

      before_action :set_bull, only: [ :show, :update, :destroy ]

      def index
        bulls = current_tenant.bulls.includes(:company)

        bulls = apply_filters(bulls)
        bulls = apply_search(bulls)
        bulls = apply_sort(bulls)
        bulls = paginate(bulls)

        render json: {
          data: bulls.as_json(
            only: [ :id, :name, :breed, :origin, :ear_tag, :company_id ],
            include: { company: { only: [ :id, :name ] } }
          ),
          meta: pagination_meta(bulls)
        }
      end

      def show
        render json: @bull.as_json(
          only: [ :id, :name, :breed, :origin, :ear_tag, :company_id ],
          include: { company: { only: [ :id, :name ] } }
        )
      end

      def create
        bull = current_tenant.bulls.new(bull_params)

        if bull.save
          render json: bull, status: :created
        else
          render json: { errors: bull.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @bull.update(bull_params)
          render json: @bull
        else
          render json: { errors: @bull.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @bull.destroy
        head :no_content
      end

      private

      def set_bull
        @bull = current_tenant.bulls.find(params[:id])
      end

      def bull_params
        params.require(:bull).permit(:name, :breed, :origin, :ear_tag, :company_id)
      end

      def apply_search(scope)
        return scope if params[:q].blank?

        scope.where(
          "LOWER(bulls.name) LIKE :q OR LOWER(bulls.breed) LIKE :q",
          q: "%#{params[:q].downcase}%"
        )
      end

      def apply_filters(scope)
        scope = scope.where(origin: params[:origin]) if params[:origin].present?
        scope = scope.where(company_id: params[:company_id]) if params[:company_id].present?
        scope = scope.where("created_at >= ?", params[:created_from]) if params[:created_from].present?
        scope = scope.where("created_at <= ?", params[:created_to]) if params[:created_to].present?

        scope
      end

      def apply_sort(scope)
        sort_by = params[:sort_by].presence || "created_at"
        sort_dir = params[:sort_dir] == "asc" ? :asc : :desc

        allowed_fields = %w[name breed created_at]

        return scope.order(created_at: :desc) unless allowed_fields.include?(sort_by)

        scope.order(sort_by => sort_dir)
      end

      def paginate(scope)
        page = params[:page].to_i > 0 ? params[:page].to_i : 1
        per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 10

        scope.page(page).per(per_page)
      end

      def pagination_meta(scope)
        {
          current_page: scope.current_page,
          next_page: scope.next_page,
          prev_page: scope.prev_page,
          total_pages: scope.total_pages,
          total_count: scope.total_count
        }
      end
    end
  end
end
