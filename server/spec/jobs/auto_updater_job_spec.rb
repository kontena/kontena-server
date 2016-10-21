require_relative '../spec_helper'

describe AutoUpdaterJob do
  before(:each) { Celluloid.boot }
  after(:each) { Celluloid.shutdown }

  let(:grid) { Grid.create!(name: 'test-grid', overlay_cidr: '10.81.0.0/23') }

  describe '#stats_enabled?' do
    it 'returns true by default' do
      config = {'server.anonymous_stats' => true}
      allow(subject.wrapped_object).to receive(:config).and_return(config)
      expect(subject.stats_enabled?).to be_truthy
    end

    it 'returns false if disabled' do
      config = {'server.anonymous_stats' => false}
      allow(subject.wrapped_object).to receive(:config).and_return(config)
      expect(subject.stats_enabled?).to be_falsey
    end
  end
end
