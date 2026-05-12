require "rails_helper"

RSpec.describe Auth::Login do
  let(:tenant) { Tenant.create!(name: "Fazenda", slug: "fazenda-teste") }

  let(:user) do
    User.create!(
      tenant: tenant,
      name: "User 1",
      email: "user@email.com",
      password: "@Senha123",
      password_confirmation: "@Senha123",
      status: :active
    )
  end

  def call_service(attrs = {})
    described_class.new(**{
      tenant: tenant,
      email: user.email,
      password: "@Senha123",
      ip_address: "127.0.0.1",
      user_agent: "RSpec"
    }.merge(attrs)).call
  end

  it "realiza login com credenciais válidas" do
    result = call_service

    expect(result[:user]).to eq(user)
    expect(result[:access_token]).to be_present
    expect(result[:refresh_token]).to be_present
    expect(result[:session]).to be_persisted
  end

  it "cria sessão de autenticação" do
    expect {
      call_service
    }.to change(AuthSession, :count).by(1)

    session = AuthSession.last

    expect(session.user).to eq(user)
    expect(session.tenant).to eq(tenant)
    expect(session.refresh_token_digest).to be_present
    expect(session.expires_at).to be > Time.current
    expect(session.ip_address).to eq("127.0.0.1")
    expect(session.user_agent).to eq("RSpec")
  end

  it "salva digest do refresh token na sessão" do
    result = call_service

    expect(result[:session].refresh_token_digest).to eq(
      Auth::RefreshToken.digest(result[:refresh_token])
    )
  end

  it "atualiza last_sign_in_at do usuário" do
    expect {
      call_service
    }.to change { user.reload.last_sign_in_at }.from(nil)
  end

  it "inválido com tenant inválido" do
    expect {
      call_service(tenant: nil)
    }.to raise_error(Auth::Error, I18n.t!("tenant.errors.invalid_tenant"))
  end

  it "inválido com email inexistente" do
    expect {
      call_service(email: "outro@email.com")
    }.to raise_error(Auth::Error, I18n.t!("auth.errors.invalid_credentials"))
  end

  it "inválido com usuário inativo" do
    user.update!(status: :inactive)

    expect {
      call_service
    }.to raise_error(Auth::Error, I18n.t!("auth.errors.inactive_user"))
  end

  it "inválido com senha inválida" do
    expect {
      call_service(password: "senha-inválida")
    }.to raise_error(Auth::Error, I18n.t!("auth.errors.invalid_credentials"))
  end
end
