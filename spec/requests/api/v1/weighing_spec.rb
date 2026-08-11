require "rails_helper"

RSpec.describe "Api::V1::Events", type: :request do
  let(:tenant) { create(:tenant) }
  let(:headers) do { "X-Tenant-Slug" => tenant.slug } end
  let(:current_user) do build(:user, tenant: tenant) end

  let(:cow) do create(:cow, tenant: tenant, weight: 180) end

  def post_weighing(weight:, occurred_at: nil)
    data = weight.nil? ? {} : { weight: weight }

    post "/api/v1/cows/#{cow.id}/events",
      params: {
        event: {
          event_type: "weighing",
          occurred_at: occurred_at,
          data: data
        }
      },
      headers: headers,
      as: :json
  end

  before do
    allow_any_instance_of(AuthenticateRequest)
      .to receive(:authenticate_request!)
      .and_return(true)

    allow_any_instance_of(AuthenticateRequest)
      .to receive(:current_user)
      .and_return(current_user)
  end

  it "cria evento de pesagem" do
    occurred_at = 1.day.ago.change(usec: 0)

    post_weighing(weight: 200, occurred_at: occurred_at)

    expect(response).to have_http_status(:created)
    expect(cow.reload.weight).to eq(200)
    expect(cow.last_weighing_at).to eq(occurred_at)
    expect(Event.last.event_type).to eq("weighing")
  end

  it "retorna 422 se weight vazio" do
    post_weighing(weight: nil)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "retorna 422 se weight negativo" do
    post_weighing(weight: -200)

    expect(response).to have_http_status(:unprocessable_content)
  end
end
