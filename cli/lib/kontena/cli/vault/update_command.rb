module Kontena::Cli::Vault
  class UpdateCommand < Kontena::Command
    include Kontena::Cli::Common

    parameter 'NAME', 'Secret name'
    parameter '[VALUE]', 'Secret value (default: STDIN)'

    option ['-u', '--upsert'], :flag, 'Create secret unless already exists', default: false
    option '--silent', :flag, "Reduce output verbosity"

    requires_current_master

    def default_value
      Kontena.stdinput("Enter value for secret '#{name}'")
    end

    def execute
      vspinner "Updating #{name.colorize(:cyan)} value in the vault " do
        client.put("secrets/#{current_grid}/#{name}", {name: name, value: value, upsert: upsert? })
      end
    end
  end
end
