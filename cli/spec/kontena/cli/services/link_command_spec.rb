require_relative "../../../spec_helper"
require "kontena/cli/services/link_command"

describe Kontena::Cli::Services::LinkCommand do

  include ClientHelpers

  describe '#execute' do
    it 'aborts if service is already linked' do
      expect(client).to receive(:get).with('services/test-grid/null/service-a').and_return({
        'links' => [
          {'alias' => 'service-b', 'grid_service_id' => "grid/service-b"}
        ]
      })
      expect {
        subject.run(['service-a', 'service-b'])
      }.to raise_error(SystemExit)
    end

    it 'sends link to master' do
      expect(client).to receive(:get).with('services/test-grid/null/service-a').and_return({
        'links' => []
      })
      expect(client).to receive(:put).with(
        'services/test-grid/null/service-a', {links: [{name: 'service-b', alias: 'service-b'}]}
      )
      subject.run(['service-a', 'service-b'])
    end
  end
end
