module ApplicationHelper
  def frontend_reset_url
    frontend_base = ENV.fetch("FRONTEND_URL")

    "#{frontend_base}/reset-password?token=#{@token}"
  end
end
