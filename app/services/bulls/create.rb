module Bulls
  class Create
    def initialize(tenant:, params:)
      @tenant = tenant
      @params = params
    end

    def call
      ActiveRecord::Base.transaction do
        breed = find_or_create_breed

        tenant.bulls.create!(bull_params.merge(breed: breed))
      end
    end

    private

    attr_reader :tenant, :params

    def bull_params
      params.except(:breed_id, :breed_name)
    end

    def find_or_create_breed
      Breeds::FindOrCreate.new(
        tenant: tenant,
        breed_id: params[:breed_id],
        breed_name: params[:breed_name]
      ).call
    end
  end
end
