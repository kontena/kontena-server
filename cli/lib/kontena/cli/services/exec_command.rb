require_relative 'services_helper'

module Kontena::Cli::Services
  class ExecCommand < Kontena::Command
    include Kontena::Cli::Common
    include Kontena::Cli::GridOptions
    include ServicesHelper

    parameter "NAME", "Service name"
    parameter "CMD ...", "Command"

    option ["-i", "--instance"], "INSTANCE", "Exec on given numbered instance, default first running" do |value| Integer(value) end
    option ["-a", "--all"], :flag, "Exec on all running instances"
    option ["--shell"], :flag, "Execute as a shell command"
    option ["--[no-]spinner"], :flag, "Execute with interactive output", attribute_name: :with_spinner, default: true

    requires_current_master
    requires_current_grid

    # Exits if exec returns with non-zero
    def exec_container(container)
      if shell?
        cmd = ['sh', '-c', cmd_list.join(' ')]
      else
        cmd = cmd_list
      end

      stdout = stderr = exit_status = nil

      if with_spinner?
        spinner "Executing command on #{container['name']}" do
          stdout, stderr, exit_status = client.post("containers/#{container['id']}/exec", {cmd: cmd})

          raise Kontena::Cli::SpinAbort if exit_status != 0
        end
      else
        stdout, stderr, exit_status = client.post("containers/#{container['id']}/exec", {cmd: cmd})
      end

      stdout.each do |chunk| $stdout.write chunk end
      stderr.each do |chunk| $stderr.write chunk end

      exit exit_status if exit_status != 0

      return true
    end

    def execute
      service_containers = client.get("services/#{parse_service_id(name)}/containers")['containers']
      service_containers.sort_by! { |container| container['instance_number'] }
      running_containers = service_containers.select{|container| container['status'] == 'running' }

      if running_containers.empty?
        exit_with_error "Service #{name} does not have any running containers"
      end

      if all?
        service_containers.each do |container|
          if container['status'] == 'running'
            exec_container(container)
          else
            warning "Service #{name} container #{container['name']} is #{container['status']}, skipping"
          end
        end
      elsif instance
        if !(container = service_containers.find{|container| container['instance_number'] == instance})
          exit_with_error "Service #{name} does not have container instance #{instance}"
        elsif container['status'] != 'running'
          exit_with_error "Service #{name} container #{container['name']} is not running, it is #{container['status']}"
        else
          exec_container(container)
        end
      else
        exec_container(running_containers.first)
      end
    end
  end
end
