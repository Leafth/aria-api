require 'rails_helper'

RSpec.describe "Api::V1::Cows", type: :request do
    let!(:tenant) { Tenant.create!(name: "Fazenda", slug: "fazenda-teste") }

    let(:headers) { { "X-Tenant-Slug" => tenant.slug } }

    def cow_params
      {
        name: "Mimosa",
        ear_tag: "001",
        birth_date: "2023-01-01",
        breed: "Nelore",
        weight: 180,
        phase: "calf",
        active: true
      }
    end

      describe "POST /api/v1/cows" do
        it "create cow" do
          expect {
            post "/api/v1/cows", params: { cow: cow_params }, headers: headers
          }.to change(Cow, :count).by(1)

          expect(response).to have_http_status(:created)
        end
      end
end
