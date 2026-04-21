class AuthSession < ApplicationRecord
  belongs_to :user
  belongs_to :tenant

  validates :refresh_token_digest, presence: true
  validates :expires_at, presence: true

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def revoked?
    revoked_at.present?
  end

  def expired?
    expires_at <= Time.current
  end

  def active?
    !revoked? && !expired?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end
end
