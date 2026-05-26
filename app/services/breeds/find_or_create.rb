module Breeds
  class FindOrCreate
    def initialize(tenant:, breed_id: nil, breed_name: nil)
      @tenant = tenant
      @breed_id = breed_id
      @breed_name = breed_name
    end

    def call
      return find_breed if breed_id.present?
      find_or_create_breed if breed_name.present?
    end

    private

    attr_reader :tenant, :breed_id, :breed_name

    def find_breed
      tenant.breeds.find(breed_id)
    end

    def find_or_create_breed
      tenant.breeds.find_or_create_by!(
        normalized_name: normalized_breed_name
      ) do |breed|
        breed.name = sanitized_breed_name
      end
    end

    def sanitized_breed_name
      breed_name.to_s.strip
    end

    def normalized_breed_name
      sanitized_breed_name.parameterize
    end
  end
end
