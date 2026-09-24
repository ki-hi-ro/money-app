require "minitest/autorun"
require "open3"
require "rbconfig"

class DeploymentConfigTest < Minitest::Test
  def check(overrides = {})
    environment = {
      "APP_HOST" => "money-app-khiro-a414f54be759.herokuapp.com",
      "DATABASE_URL" => "postgresql://user:private-password@database.example.test/app",
      "MAIL_FROM" => "MoneyApp <noreply@example.test>",
      "SMTP_ADDRESS" => "smtp.example.test", "SMTP_PORT" => "587",
      "SMTP_USERNAME" => "user", "SMTP_PASSWORD" => "private-mail-password"
    }.merge(overrides)
    Open3.capture2e(environment, RbConfig.ruby, File.expand_path("../bin/check-deploy-config", __dir__), unsetenv_others: true)
  end

  def test_accepts_complete_configuration
    output, status = check
    assert status.success?, output
  end

  def test_rejects_incomplete_or_invalid_configuration_without_disclosing_secrets
    [{ "SMTP_USERNAME" => "" }, { "APP_HOST" => "https://example.test/path" },
     { "DATABASE_URL" => "sqlite:///tmp/app.db" }, { "SMTP_PORT" => "0" }].each do |invalid|
      output, status = check(invalid)
      refute status.success?
      refute_includes output, "private-password"
      refute_includes output, "private-mail-password"
    end
  end
end
