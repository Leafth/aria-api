require 'rails_helper'

RSpec.describe "Api::V1::Events", type: :request do
  let(:tenant) { create(:tenant) }
  let(:headers) do { "X-Tenant-Slug" => tenant.slug } end
  let(:current_user) do build(:user, tenant: tenant) end

  let(:cow) do
    create(
      :cow,
      tenant: tenant
    )
  end

  def post_inactivation(reason:)
    data = reason.nil? ? {} : { reason: reason }

    post "/api/v1/cows/#{cow.id}/events",
      params: {
        event: {
          event_type: "inactivation",
          data: data
        }
      },
      headers: headers
  end

  before do
    allow_any_instance_of(AuthenticateRequest)
      .to receive(:authenticate_request!)
      .and_return(true)

    allow_any_instance_of(AuthenticateRequest)
      .to receive(:current_user)
      .and_return(current_user)
  end

  it "cria evento que realiza inativação de cow com reason sale" do
    post_inactivation(reason: "sale")

    expect(response).to have_http_status(:created)
    expect(cow.reload.active).to eq(false)
  end

  it "cria evento que realiza inativação de cow com reason death" do
    post_inactivation(reason: "death")

    expect(response).to have_http_status(:created)
    expect(cow.reload.active).to eq(false)
  end

  it "retorna 422 se reason vazia" do
    post_inactivation(reason: nil)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(cow.reload.active).to eq(true)
  end

  it "retorna 422 se reason inválida" do
    post_inactivation(reason: "outro")

    expect(response).to have_http_status(:unprocessable_entity)
    expect(cow.reload.active).to eq(true)
  end
end
