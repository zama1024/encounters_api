ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
abort("The Rails environment is running in production mode!") if defined?(Rails) && Rails.env.production?

require 'spec_helper'
require 'rspec/rails'

# Maintain test schema (if using ActiveRecord)
if defined?(ActiveRecord::Migration)
  begin
    ActiveRecord::Migration.maintain_test_schema!
  rescue ActiveRecord::PendingMigrationError => e
    abort e.message
  end
end

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures" if defined?(Rails)
  config.use_transactional_fixtures = true if defined?(ActiveRecord)
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
