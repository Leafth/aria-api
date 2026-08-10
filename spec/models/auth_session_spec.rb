require 'rails_helper'

RSpec.describe AuthSession, type: :model do
  it "é válida com dados válidos" do
    auth_session = build(:auth_session)

    expect(auth_session).to be_valid
  end

  it "inválido sem tenant" do
    auth_session = build(:auth_session, tenant: nil)

    expect(auth_session).not_to be_valid
    expect(auth_session.errors[:tenant]).to be_present
  end

  it "inválido sem user" do
    auth_session = build(:auth_session, user: nil)

    expect(auth_session).not_to be_valid
    expect(auth_session.errors[:user]).to be_present
  end

  it "inválido sem refresh_token_digest" do
    auth_session = build(:auth_session, refresh_token_digest: nil)

    expect(auth_session).not_to be_valid
    expect(auth_session.errors[:refresh_token_digest]).to be_present
  end

  it "inválido sem expires_at" do
    auth_session = build(:auth_session, expires_at: nil)

    expect(auth_session).not_to be_valid
    expect(auth_session.errors[:expires_at]).to be_present
  end

  it "revoked retorna true quando sessão está revogada" do
    auth_session = build(:auth_session, :revoked)

    expect(auth_session.revoked?).to eq(true)
  end

  it "revoked retorna false quando sessão não está revogada" do
    auth_session = build(:auth_session)

    expect(auth_session.revoked?).to eq(false)
  end

  it "expired retorna true quando sessão está expirada" do
    auth_session = build(:auth_session, :expired)

    expect(auth_session.expired?).to eq(true)
  end

  it "expired retorna false quando sessão não está expirada" do
    auth_session = build(:auth_session)

    expect(auth_session.expired?).to eq(false)
  end

  it "retorna true quando sessão está ativa" do
    auth_session = build(:auth_session)

    expect(auth_session.active?).to eq(true)
  end

  it "retorna false quando sessão não está ativa" do
    auth_session = build(:auth_session, :revoked)

    expect(auth_session.active?).to eq(false)
  end

  it "revoga a sessão" do
    auth_session = create(:auth_session)

    auth_session.revoke!

    expect(auth_session.reload.revoked_at).to be_present
    expect(auth_session.revoked?).to eq(true)
  end
end
