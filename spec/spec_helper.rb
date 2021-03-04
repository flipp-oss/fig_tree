# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

RSpec.configure do |config|
  config.full_backtrace = true

  # true by default for RSpec 4.0
  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.mock_with(:rspec) do |mocks|
    mocks.yield_receiver_to_any_instance_implementation_blocks = true
    mocks.verify_partial_doubles = true
  end
end
