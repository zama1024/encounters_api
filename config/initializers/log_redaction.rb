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

    # Add support for ActiveSupport::TaggedLogging which expects formatters
    # to respond to `tagged(*tags) { ... }`. Delegate to the base formatter
    # when it supports tagged, otherwise just yield.
    def tagged(*tags)
      if @base.respond_to?(:tagged)
        @base.tagged(*tags) { yield self }
      else
        yield self
      end
    end

    # Support ActiveSupport::TaggedLogging push/pop/clear tag operations.
    # Delegate to base formatter when available, otherwise maintain a simple
    # thread-local tag stack so tagging works even without base support.
    def push_tags(*tags)
      if @base.respond_to?(:push_tags)
        @base.push_tags(*tags)
      else
        Thread.current[thread_key] ||= []
        Thread.current[thread_key].concat(tags)
      end
    end

    def pop_tags(n = 1)
      if @base.respond_to?(:pop_tags)
        @base.pop_tags(n)
      else
        arr = Thread.current[thread_key] ||= []
        n.times { arr.pop } if n.to_i > 0
        arr
      end
    end

    def clear_tags!
      if @base.respond_to?(:clear_tags!)
        @base.clear_tags!
      else
        Thread.current[thread_key] = []
      end
    end

    # Expose thread_key so formatters that rely on a specific key can still work.
    def thread_key
      return @base.thread_key if @base.respond_to?(:thread_key)
      :"activesupport_tagged_logging_tags"
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
