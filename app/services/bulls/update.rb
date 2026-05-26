module Bulls
  class Update
    def initialize(bull:, params:)
      @bull = bull
      @params = params
    end

    def call
      ActiveRecord::Base.transaction do
        bull.update!(
          bull_params.merge(optional_breed)
        )

        bull
      end
    end

    private

    attr_reader :bull, :params

    def bull_params
      params.except(:breed_id, :breed_name)
    end

    def optional_breed
      return {} if params[:breed_id].blank? && params[:breed_name].blank?

      {
        breed: Breeds::FindOrCreate.new(
          tenant: bull.tenant,
          breed_id: params[:breed_id],
          breed_name: params[:breed_name]
        ).call
      }
    end
  end
end
