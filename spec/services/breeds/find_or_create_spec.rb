require "rails_helper"

RSpec.describe Breeds::FindOrCreate do
  let(:tenant) { create(:tenant) }

  def call_service(**params)
    described_class.new(
      tenant: tenant,
      **params
    ).call
  end

  describe "#call" do
    context "quando breed_id é informado" do
      it "retorna a raça existente" do
        breed = create(:breed, tenant: tenant, name: "Nelore")

        result = call_service(breed_id: breed.id)

        expect(result).to eq(breed)
      end
    end

    context "quando breed_name é informado" do
      it "cria uma nova raça normalizada" do
        result = call_service(breed_name: " Jersey ")

        expect(result.name).to eq("Jersey")
        expect(result.normalized_name).to eq("jersey")
      end

      it "reaproveita uma raça existente com mesmo nome normalizado" do
        existing_breed = create(
          :breed,
          tenant: tenant,
          name: "Nelore"
        )

        result = call_service(breed_name: " nelore ")

        expect(result).to eq(existing_breed)
      end
    end
  end
end
