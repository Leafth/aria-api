require 'rails_helper'

RSpec.describe User, type: :model do
  let(:tenant) { Tenant.create!(name: "Fazenda", slug: "fazenda-teste") }

  def build_user(attrs = {})
    User.new({
      tenant: tenant,
      name: "User 1",
      email: "user@email.com",
      password: "@Senha123",
      password_confirmation: "@Senha123",
      status: :active
    }.merge(attrs))
  end

  it "é válido com dados válidos" do
    user = build_user

    expect(user).to be_valid
  end

  it "inválido sem tenant" do
    user = build_user(tenant: nil)

    expect(user).not_to be_valid
    expect(user.errors[:tenant]).to be_present
  end

  it "inválido sem nome" do
    user = build_user(name: nil)

    expect(user).not_to be_valid
    expect(user.errors[:name]).to be_present
  end

  it "inválido com email inválido" do
    user = build_user(email: "email")

    expect(user).not_to be_valid
    expect(user.errors[:email]).to be_present
  end

  it "inválido se email já existente" do
    User.create!(
      tenant: tenant,
      name: "User 2",
      email: "user@email.com",
      password: "@Senha123",
      password_confirmation: "@Senha123",
      status: :active
    )

    user = build_user

    expect(user).not_to be_valid
    expect(user.errors[:email]).to be_present
  end

  it "inválido com senha sem número" do
    user = build_user(password: "Senhaaaa", password_confirmation: "Senhaaaa")

    expect(user).not_to be_valid
    expect(user.errors[:password]).to be_present
  end

  it "inválido com senha sem letra" do
    user = build_user(password: "12345678", password_confirmation: "12345678")

    expect(user).not_to be_valid
    expect(user.errors[:password]).to be_present
  end

  it "inválido com senha com menos de 8 caracteres" do
    user = build_user(password: "@Senha", password_confirmation: "@Senha")

    expect(user).not_to be_valid
    expect(user.errors[:password]).to be_present
  end

  it "inválido com senha com outros caracteres especiais" do
    user = build_user(password: "*Senha123", password_confirmation: "*Senha123")

    expect(user).not_to be_valid
    expect(user.errors[:password]).to be_present
  end

  it "inválido com confirmação de senha diferente" do
    user = build_user(password_confirmation: "Senha123")

    expect(user).not_to be_valid
    expect(user.errors[:password_confirmation]).to be_present
  end
end
