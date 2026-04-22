class CustomDeviseMailer < Devise::Mailer
  helper :application
  default template_path: "devise/mailer"
end
