module Cows
  class Create
    def initialize(tenant:, params:)
      @tenant = tenant
      @params = params
    end

    def call
      ActiveRecord::Base.transaction do
        cow = tenant.cows.create!(params)

        create_initial_weighing!(cow)

        cow
      end
    end

    private

    attr_reader :tenant, :params

    def create_initial_weighing!(cow)
      Events::Weighing.new(
        cow: cow,
        params: {
          occurred_at: cow.created_at,
          data: {
            weight: cow.weight
          }
        }
      ).call
    end
  end
end
