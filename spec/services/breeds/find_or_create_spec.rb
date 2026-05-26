require "rails_helper"

RSpec.describe Breeds::FindOrCreate do
  let!(:tenant) do
    Tenant.create!(name: "Fazenda", slug: "fazenda-teste", status: :active)
  end

  describe "#call" do
    context "quando breed_id é informado" do
      it "retorna a raça existente" do
        breed = tenant.breeds.create!(
          name: "Nelore"
        )

        result = described_class.new(
          tenant: tenant,
          breed_id: breed.id
        ).call

        expect(result).to eq(breed)
      end
    end

    context "quando breed_name é informado" do
      it "cria uma nova raça normalizada" do
        result = described_class.new(
          tenant: tenant,
          breed_name: " Jersey "
        ).call

        expect(result.name).to eq("Jersey")
        expect(result.normalized_name).to eq("jersey")
      end

      it "reaproveita uma raça existente com mesmo nome normalizado" do
        existing_breed = tenant.breeds.create!(
          name: "Nelore"
        )

        result = described_class.new(
          tenant: tenant,
          breed_name: " nelore "
        ).call

        expect(result).to eq(existing_breed)
      end
    end
  end
end
