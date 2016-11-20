require_relative '../../spec_helper'

describe Stacks::Delete do
  let(:user) { User.create!(email: 'joe@domain.com')}
  let(:grid) { Grid.create!(name: 'test-grid') }
  let(:stack) {
    stack = Stack.create!(grid: grid, name: 'stack')
    redis = GridService.create(grid: grid, name: 'redis', image_name: 'redis:2.8', stack: stack)
    web = GridService.create(grid: grid, name: 'web', image_name: 'web:latest', stack: stack)
    stack.reload
  }
  let(:default_stack) { grid.stacks.find_by(name: 'default') }
  let(:worker_klass) do
    Class.new do
      include Celluloid
    end
  end
  let(:worker) do
    worker = worker_klass.new
    Celluloid::Actor[:stack_remove_worker] = worker
    worker
  end

  describe '#run' do
    it 'calls stack remove worker' do
      expect(worker.wrapped_object).to receive(:perform).once.with(stack.id)
      outcome = described_class.run(stack: stack)
      expect(outcome.success?).to be_truthy
    end

    it 'allows to remove stack that has links within stack' do
      foo = GridServices::Create.run(
        grid: grid, stateful: false,
        name: 'foo', image: 'foo:latest', stack: stack,
        links: [
          { name: 'stack/web', alias: 'web' }
        ]
      )
      expect(worker.wrapped_object).to receive(:perform).once.with(stack.id)
      outcome = described_class.run(stack: stack)
      expect(outcome.success?).to be_truthy
    end

    it 'does not allow to remove default stack' do
      expect(worker.wrapped_object).not_to receive(:perform)
      mutation = described_class.new(stack: default_stack)
      outcome = mutation.run
      expect(outcome.success?).to be_falsey
    end

    it 'does not allow to remove stack that has linked from other stacks' do
      default_stack = grid.stacks.find_by(name: 'default')
      stack
      foo = GridServices::Create.run(
        grid: grid, stateful: false,
        name: 'foo', image: 'foo:latest', stack: default_stack,
        links: [
          { name: 'stack/web', alias: 'web' }
        ]
      )
      expect(worker.wrapped_object).not_to receive(:perform)
      outcome = described_class.run(stack: stack)
      expect(outcome.success?).to be_falsey
    end
  end
end
