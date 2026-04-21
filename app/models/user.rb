class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable

  belongs_to :tenant
  has_many :auth_sessions, dependent: :destroy

  devise :database_authenticatable,
         :recoverable, :validatable

  enum :status, { active: 0, inactive: 1 }

  before_validation :normalize_email

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { scope: :tenant_id, case_sensitive: false }
  validate :password_complexity

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def password_complexity
    return if password.blank?

    regex = /\A(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d!@#$%&]+\z/

    unless password.match?(regex) && password.length >= 8
      errors.add :password,
                 "Senha com formato inválido: mínimo 8 caracteres, com letras, números e apenas ! @ # $ % &"
    end
  end
end
