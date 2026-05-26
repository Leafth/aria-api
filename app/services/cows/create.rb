module Cows
  class Create
    def initialize(tenant:, params:)
      @tenant = tenant
      @params = params
    end

    def call
      ActiveRecord::Base.transaction do
        breed = find_or_create_breed

        cow = tenant.cows.create!(cow_params.merge(breed: breed))

        create_initial_weighing!(cow)

        cow
      end
    end

    private

    attr_reader :tenant, :params

    def cow_params
      params.except(:breed_id, :breed_name)
    end

    def find_or_create_breed
      Breeds::FindOrCreate.new(
        tenant: tenant,
        breed_id: params[:breed_id],
        breed_name: params[:breed_name]
      ).call
    end

    def create_initial_weighing!(cow)
      Events::Weighing.new(
        cow: cow,
        params: {
          occurred_at: cow.created_at.beginning_of_day,
          data: {
            weight: cow.weight
          }
        }
      ).call
    end
  end
end
