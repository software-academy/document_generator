require 'spec_helper'

module DocumentGenerator
  describe CLI do
    describe '.start' do
      context 'when a url is supplied' do
        let(:args) { %w(--url http://some.repo.url) }
        let(:repository) { instance_double('Repository') }

        it 'sends the :generate message to a new Repository' do
          expect(Repository).to receive(:new).with('http://some.repo.url').and_return repository
          expect(repository).to receive(:generate)

          CLI.start(args)
        end

      end
      context 'when no args are supplied' do
        let(:args) { [] }

        it 'raises a MissingArgument error' do
          expect { CLI.start(args) }.to raise_error(OptionParser::MissingArgument)
        end
      end
    end
  end
end