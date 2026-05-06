class AuthenticationError < StandardError; end

module AuthenticateRequest
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request!
  end

  private

  def authenticate_request!
    payload = decode_token!
    session = find_session!(payload)
    user = session.user

    raise Auth::Error, "Usuário inativo" unless user.active?

    @current_user = user
    @current_session = session
  end

  def access_token
    header = request.headers["Authorization"]
    return header.split(" ").last if header.present?

    cookies[:access_token]
  end

  def decode_token!
    token = access_token
    raise Auth::Error, "Token ausente" if token.blank?

    payload = Auth::AccessToken.decode(token)

    raise Auth::Error, "Token expirado" if payload["exp"].blank?
    raise Auth::Error, "Token expirado" if payload["exp"] < Time.current.to_i

    payload

  rescue JWT::DecodeError
    raise Auth::Error, "Token inválido"
  end

  def find_session!(payload)
    session = AuthSession.find_by(id: payload["session_id"])

    raise Auth::Error, "Sessão não encontrada" unless session
    raise Auth::Error, "Sessão revogada" if session.revoked?
    raise Auth::Error, "Sessão expirada" if session.expired?
    raise Auth::Error, "Tenant inválido" unless session.tenant_id == current_tenant.id

    session
  end

  def current_user
    @current_user
  end

  def current_session
    @current_session
  end
end
