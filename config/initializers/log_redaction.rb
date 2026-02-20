# Log redaction layer: sanitizes log messages and exception text before emitting.
module LogRedaction
  REDACTED = "[REDACTED]"

  SENSITIVE_KEYS = %w[
    patient_id
    patient_name
    name
    ssn
    dob
    mrn
    address
    phone
    email
  ].freeze

  EMAIL_REGEX = /\b[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}\b/i
  SSN_REGEX = /\b\d{3}-\d{2}-\d{4}\b/
  PHONE_REGEX = /(?:\+?\d{1,3}[-.\s]?)?(?:\(\d{3}\)|\d{3})[-.\s]?\d{3}[-.\s]?\d{4}/

  def self.redact(text)
    return text unless text.is_a?(String)
    s = text.dup

    SENSITIVE_KEYS.each do |k|
      s.gsub!(/(\"#{Regexp.escape(k)}\"|\b#{Regexp.escape(k)}\b)\s*[:=]{1,2}\s*(\"[^\"]+\"|'[^']+'|[^,\}\]\s]+)/i) do
        "#{Regexp.last_match(1)}: \"#{REDACTED}\""
      end
      s.gsub!(/(\b#{Regexp.escape(k)}\b)\s*=>\s*([^,\}\]\s]+)/i) do
        "#{Regexp.last_match(1)}=>\"#{REDACTED}\""
      end
    end

    s.gsub!(EMAIL_REGEX, REDACTED)
    s.gsub!(SSN_REGEX, REDACTED)
    s.gsub!(PHONE_REGEX, REDACTED)

    s
  rescue
    text
  end

  class RedactingFormatter
    def initialize(base_formatter = nil)
      @base = base_formatter
    end

    def call(severity, timestamp, progname, msg)
      message = (msg.respond_to?(:to_s) ? msg.to_s : msg.inspect) rescue msg.to_s
      redacted = LogRedaction.redact(message)

      if @base.respond_to?(:call)
        @base.call(severity, timestamp, progname, redacted)
      else
        "#{timestamp.utc.iso8601} #{severity} -- #{progname}: #{redacted}\n"
      end
    end
  end
end

Rails.application.config.after_initialize do
  begin
    current = Rails.logger.formatter
    Rails.logger.formatter = LogRedaction::RedactingFormatter.new(current)

    if defined?(ActiveRecord::Base) && ActiveRecord::Base.logger
      ActiveRecord::Base.logger.formatter = Rails.logger.formatter
    end

    if defined?(ActionCable) && ActionCable.server && ActionCable.server.logger
      ActionCable.server.logger.formatter = Rails.logger.formatter
    end
  rescue => e
    STDERR.puts "Log redaction initializer failed: #{e.message}"
  end
end
