require_relative 'test_helper'

class LogRedactionTest < ActiveSupport::TestCase
  test "redacts sensitive patterns and keys" do
    input = 'patient_id: "ABC123", "patient_name"=>"Jane Doe", email: "jane.doe@example.com", ssn: "123-45-6789", phone: "(123) 456-7890"'
    out = LogRedaction.redact(input)

    assert_not out.include?("ABC123"), "patient_id should be redacted"
    assert_not out.include?("Jane Doe"), "patient_name should be redacted"
    assert_not out.include?("jane.doe@example.com"), "email should be redacted"
    assert_not out.include?("123-45-6789"), "ssn should be redacted"
    assert_not out.include?("(123) 456-7890"), "phone should be redacted"

    assert_includes out, LogRedaction::REDACTED
  end

  test "redacting formatter strips sensitive data from logged messages" do
    base_formatter = Logger::Formatter.new
    fmt = LogRedaction::RedactingFormatter.new(base_formatter)

    msg = 'Encounter created for patient_id=ABC123, contact=jane.doe@example.com'
    result = fmt.call('INFO', Time.now.utc, 'test', msg)

    assert_not result.include?("ABC123")
    assert_not result.include?("jane.doe@example.com")
    assert_includes result, LogRedaction::REDACTED
  end
end
