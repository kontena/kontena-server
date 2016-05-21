module Kontena::Cli::Registry
  class RemoveCommand < Clamp::Command
    include Kontena::Cli::Common

    option "--confirm", :flag, "Confirm remove", default: false, attribute_name: :confirmed

    def execute
      require_api_url
      token = require_token
      confirm unless confirmed?

      registry = client(token).get("services/#{current_grid}/registry") rescue nil
      abort("Docker Registry service does not exist") if registry.nil?

      client(token).delete("services/#{current_grid}/registry")
    end
  end
end
