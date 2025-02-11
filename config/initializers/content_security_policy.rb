# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

# Rails.application.config.content_security_policy do |policy|
#   policy.default_src :self, :https
#   policy.font_src    :self, :https, :data
#   policy.img_src     :self, :https, :data
#   policy.object_src  :none
#   policy.script_src  :self, :https
#   policy.style_src   :self, :https
#   # Specify URI for violation reports
#   # policy.report_uri "/csp-violation-report-endpoint"
# end

domains = ["*.cloud.sap"]

Rails.application.config.content_security_policy do |policy|
  policy.connect_src :self, :https, :wss, *domains
end