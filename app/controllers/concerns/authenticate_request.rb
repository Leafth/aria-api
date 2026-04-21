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

    raise AuthenticationError, "Usuário inativo" unless user.active?

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
    raise AuthenticationError, "Token ausente" if token.blank?

    payload = Auth::AccessToken.decode(token)

    raise AuthenticationError, "Token expirado" if payload["exp"] < Time.current.to_i

    payload
  rescue JWT::DecodeError
    raise AuthenticationError, "Token inválido"
  end

  def find_session!(payload)
    session = AuthSession.find_by(id: payload["session_id"])

    raise AuthenticationError, "Sessão não encontrada" unless session
    raise AuthenticationError, "Sessão revogada" if session.revoked?
    raise AuthenticationError, "Sessão expirada" if session.expired?
    raise AuthenticationError, "Tenant inválido" unless session.tenant_id == current_tenant.id

    session
  end

  def current_user
    @current_user
  end

  def current_session
    @current_session
  end
end
