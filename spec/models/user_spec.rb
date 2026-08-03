require 'rails_helper'

RSpec.describe User, type: :model do
  it "é válido com dados válidos" do
    user = build(:user)

    expect(user).to be_valid
  end

  it "inválido sem tenant" do
    user = build(:user, tenant: nil)

    expect(user).not_to be_valid
    expect(user.errors[:tenant]).to be_present
  end

  it "inválido sem nome" do
    user = build(:user, name: nil)

    expect(user).not_to be_valid
    expect(user.errors[:name]).to be_present
  end

  it "inválido com email inválido" do
    user = build(:user, email: "email ")

    expect(user).not_to be_valid
    expect(user.errors[:email]).to be_present
  end

  it "inválido se email já existente" do
    existing_user = create(:user)

    user = build(:user, tenant: existing_user.tenant, email: existing_user.email)

    expect(user).not_to be_valid
    expect(user.errors[:email]).to be_present
  end

  it "inválido com senha sem número" do
    user = build(:user, password: "Senhaaaa", password_confirmation: "Senhaaaa")

    expect(user).not_to be_valid
    expect(user.errors[:password]).to be_present
  end

  it "inválido com senha sem letra" do
    user = build(:user, password: "12345678", password_confirmation: "12345678")

    expect(user).not_to be_valid
    expect(user.errors[:password]).to be_present
  end

  it "inválido com senha com menos de 8 caracteres" do
    user = build(:user, password: "@Senha", password_confirmation: "@Senha")

    expect(user).not_to be_valid
    expect(user.errors[:password]).to be_present
  end

  it "inválido com senha com outros caracteres especiais" do
    user = build(:user, password: "*Senha123", password_confirmation: "*Senha123")

    expect(user).not_to be_valid
    expect(user.errors[:password]).to be_present
  end

  it "inválido com confirmação de senha diferente" do
    user = build(:user, password_confirmation: "Senha123")

    expect(user).not_to be_valid
    expect(user.errors[:password_confirmation]).to be_present
  end
end
