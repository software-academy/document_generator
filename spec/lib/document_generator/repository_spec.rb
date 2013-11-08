require 'spec_helper'

require 'fileutils'

module DocumentGenerator
  describe Repository do
    let(:url) { 'https://github.com/stevenhallen/document_generator.git' }
    let(:repository) { Repository.new(url) }

    describe '.menu_relative_filename' do
      it 'is _includes/menu.md' do
        expect(Repository.menu_relative_filename).to eq '_includes/menu.md'
      end
    end

    describe '#base_url' do
      let(:expected) { 'https://github.com/stevenhallen/document_generator/' }

      context 'when the url is a git url that is read-only' do
        let(:url) { 'git://github.com/stevenhallen/document_generator.git' }

        it 'is the https url without the .git' do
          expect(repository.base_url).to eq expected
        end
      end

      context 'when the url is a git url that is read-write' do
        let(:url) { 'git@github.com:stevenhallen/document_generator.git' }

        it 'is the https url without the .git' do
          expect(repository.base_url).to eq expected
        end
      end

      context 'when the url is a http url' do
        let(:url) { 'http://github.com/stevenhallen/document_generator.git' }

        it 'is the https url without the .git' do
          expect(repository.base_url).to eq expected
        end
      end
    end

    describe '#name' do
      let(:url) { 'https://github.com/stevenhallen/document_generator.git' }

      it 'is the last path segment from the normalized uri' do
        expect(repository.name).to eq 'document_generator'
      end
    end

    describe '#generate' do
      let(:url) { 'https://github.com/stevenhallen/rails_getting_started_bdd.git' }

      let(:docs) { Dir.glob(File.expand_path('../../../../*.md', __FILE__)) }
      let(:root) { File.expand_path('../../../../.', __FILE__) }
      let(:layouts) { File.expand_path('../../../../_layouts', __FILE__) }

      before do
        FileUtils.rmtree(layouts) if Dir.exists?(layouts)
        FileUtils.rm(docs)

        Dir.mkdir(layouts)
      end

      it 'creates files in the root folder' do
        expect { repository.generate }.to change { Dir.entries(root) }
      end

      it 'creates files in the layouts folder' do
        expect { repository.generate }.to change { Dir.entries(layouts) }
      end
    end
  end
end
