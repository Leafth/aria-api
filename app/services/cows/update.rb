# app/services/cows/update.rb
module Cows
  class Update
    def initialize(cow:, params:)
      @cow = cow
      @params = params
    end

    def call
      ActiveRecord::Base.transaction do
        cow.update!(cow_params.merge(breed_attributes))

        cow
      end
    end

    private

    attr_reader :cow, :params

    def cow_params
      params.except(:breed_id, :breed_name)
    end

    def breed_attributes
      return {} if params[:breed_id].blank? && params[:breed_name].blank?

      {
        breed: Breeds::FindOrCreate.new(
          tenant: cow.tenant,
          breed_id: params[:breed_id],
          breed_name: params[:breed_name]
        ).call
      }
    end
  end
end
