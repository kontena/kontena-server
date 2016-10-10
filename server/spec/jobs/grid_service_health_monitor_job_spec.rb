require_relative '../spec_helper'

describe GridServiceHealthMonitorJob do
  before(:each) { Celluloid.boot }
  after(:each) { Celluloid.shutdown }

  let(:grid) { Grid.create(name: 'test')}
  let(:service) { GridService.create(name: 'test', image_name: 'foo/bar:latest', grid: grid)}

  let(:subject) do
    described_class.new
  end

  describe '#handle_event' do
    it 'create deployment' do
      expect(subject.wrapped_object).to receive(:deploy_needed?).and_return(true)
      subject.handle_event({'id' => service.id})
      expect(GridServiceDeploy.count).to eq(1)
    end

    it 'create deployment' do
      expect(subject.wrapped_object).to receive(:deploy_needed?).and_return(false)
      subject.handle_event({'id' => service.id})
      expect(GridServiceDeploy.count).to eq(0)
    end

  end

  describe '#deploy_needed?' do
    it 'return false when service healthy enough' do
      service = double(
        {
          health_status: {healthy: 4, total: 5},
          deploy_opts: double({min_health: 0.8}),
          running?: true
        })
      expect(subject.deploy_needed?(service)).to be_falsey
    end

    it 'return true when service not healthy enough' do
      service = double(
        {
          health_status: {healthy: 1, total: 6},
          deploy_opts: double({min_health: 0.8}),
          running?: true,
          deploy_pending?: false
        })
      expect(subject.deploy_needed?(service)).to be_truthy
    end

    it 'return false when service not healthy enough but deploy pending' do
      service = double(
        {
          health_status: {healthy: 1, total: 6},
          deploy_opts: double({min_health: 0.8}),
          running?: true,
          deploy_pending?: true
        })
      expect(subject.deploy_needed?(service)).to be_falsey
    end

    it 'returns false when service not healthy enough but not running' do
      service = double(
        {
          health_status: {healthy: 1, total: 5},
          deploy_opts: double({min_health: 0.8}),
          running?: false
        })
      expect(subject.deploy_needed?(service)).to be_falsey
    end
  end
end
