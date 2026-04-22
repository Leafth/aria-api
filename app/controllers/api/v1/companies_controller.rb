module Api
  module V1
    class CompaniesController < BaseController
      include CurrentTenant
      include AuthenticateRequest

      before_action :set_company, only: [ :show ]

      def index
        companies = current_tenant.companies

        companies = apply_filters(companies)
        companies = apply_search(companies)
        companies = apply_sort(companies)

        companies = paginate(companies)

        render json: {
          data: companies,
          meta: pagination_meta(companies)
        }, status: :ok
      end

      def show
        render json: @company, status: :ok
      end

      def create
        company = current_tenant.companies.new(company_params)

        if company.save
          render json: company, status: :created
        else
          render json: { errors: company.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_company
        @company = current_tenant.companies.find(params[:id])
      end

      def company_params
        params.require(:company).permit(:name, :description)
      end

      def apply_search(scope)
        return scope if params[:q].blank?

        scope.where("LOWER(name) LIKE :q", q: "%#{params[:q].downcase}%")
      end

      def apply_filters(scope)
        scope = scope.where("created_at >= ?", params[:created_from]) if params[:created_from].present?
        scope = scope.where("created_at <= ?", params[:created_to]) if params[:created_to].present?

        scope
      end

      def apply_sort(scope)
        sort_by = params[:sort_by].presence || "created_at"
        sort_dir = params[:sort_dir] == "asc" ? :asc : :desc

        allowed_fields = %w[name created_at]

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
