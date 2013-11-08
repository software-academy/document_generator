# coding: utf-8

require 'spec_helper'

describe DocumentGenerator::Commit do
  let(:commit) { described_class.new(base_url, git_commit) }
  let(:git_commit) { double(message: message, sha: sha) }
  let(:base_url) { 'http://github.com/stevenhallen/document_generator' }
  let(:message) { 'Some commit message' }
  let(:sha) { 'da39a3ee5e6b4b0d3255bfef95601890afd80709' }

  describe '#diff_files' do
    let(:git_commit) { double(parent: parent) }

    context 'when the git_commit has a parent' do
      let(:parent) { double().as_null_object }
      let(:git_diff) { %w(1 2 3) }
      let(:wrapped_git_diff) do
        git_diff.map do |git_diff_file|
          DocumentGenerator::DiffFile.new(git_diff_file)
        end
      end

      before { parent.should_receive(:diff).with(git_commit).and_return git_diff }

      it 'is an array of wrapped diff files' do
        expect(commit.diff_files).to be_an(Array)
      end

      it 'has three items' do
        expect(commit.diff_files).to have(3).items
      end

      it 'is an array of DiffFiles wrapping each git diff file' do
        commit.diff_files.zip(wrapped_git_diff).each do |actual, expected|
          expect(actual).to be_a(DocumentGenerator::DiffFile)
          expect(actual.git_diff_file).to eq expected.git_diff_file
        end
      end
    end

    context 'when the git_commit does not have a parent' do
      let(:parent) {nil}

      it 'is empty' do
        expect(commit.diff_files).to be_empty
      end
    end
  end

  describe '#relative_filename' do
    it 'is the filename' do
      expect(commit.relative_filename).to eq 'some-commit-message.md'
    end
  end

  describe '#create' do
    let(:parent) { double().as_null_object }
    let(:git_commit) { double(parent: parent, message: message, sha: sha) }
    let(:content) { File.open(commit.relative_filename).read }
    let(:sha) { 'da39a3ee5e6b4b0d3255bfef95601890afd80709' }

    context 'when the commit is the first commit (i.e., it has no parent)' do
      let(:parent) { nil }
      let(:message) { 'first commit' }
      let(:expected_content) do
        <<-EOF
---
layout: default
title: first commit
---

<h1 id="main">first commit</h1>

### Additional Resources

* [Changes in this step in `diff` format](http://github.com/stevenhallen/commit/da39a3ee5e6b4b0d3255bfef95601890afd80709)

EOF

      end

      it 'writes the expected content to the file' do
        commit.create
        expect(content).to eq expected_content
      end
    end

    context 'when the commit has a diff from its parent' do
      before do
        expect(parent).to receive(:diff).with(git_commit).and_return git_diff_files
        expect(DocumentGenerator::DiffFile).to receive(:new).and_return diff_file
      end

      let(:message) { 'some commit message' }
      let(:diff_file) { double(content: 'the diff_file content').as_null_object }
      let(:git_diff_file) { double().as_null_object }
      let(:git_diff_files) { [git_diff_file] }
      let(:expected_content) do
        <<-EOF
---
layout: default
title: some commit message
---

<h1 id="main">some commit message</h1>
the diff_file content
### Additional Resources

* [Changes in this step in `diff` format](http://github.com/stevenhallen/commit/da39a3ee5e6b4b0d3255bfef95601890afd80709)

EOF
      end

      it 'writes the expected content to the file' do
        commit.create
        expect(content).to eq expected_content
      end
    end
  end

  describe '#header' do
    context 'when the commit message has one line' do
      let(:message) {'This is one line'}
      let(:expected_header) do
<<-EXPECTED
---
layout: default
title: This is one line
---

<h1 id="main">This is one line</h1>
EXPECTED
      end

      it 'uses the entire commit message' do
        expect(commit.header).to eq expected_header
      end
    end

    context 'when the commit message has more than one line' do
      let(:message) {"This is one line\nThis is a second line."}
      let(:expected_header) do
<<-EXPECTED
---
layout: default
title: This is one line
---

<h1 id="main">This is one line</h1>
EXPECTED
      end

      it 'uses the first line of the commit message' do
        expect(commit.header).to eq expected_header
      end
    end
  end

  describe '#additional' do
    let(:expected_additional) do
<<-EXPECTED_ADDITIONAL

### Additional Resources

* [Changes in this step in `diff` format](http://github.com/stevenhallen/commit/da39a3ee5e6b4b0d3255bfef95601890afd80709)

EXPECTED_ADDITIONAL
    end

    it 'includes a link to the commit' do
      expect(commit.additional).to eq expected_additional
    end
  end

  describe '#details_of_commit_message' do
    context 'when the commit message is one line' do
      let(:message) { 'One line' }

      it 'is nil' do
        expect(commit.details_of_commit_message).to be_nil
      end
    end

    context 'when the commit message is multiple lines' do
      let(:message) { "One line\nTwo lines\nThree and more" }

      it 'is not empty' do
        expect(commit.details_of_commit_message).to eq "Two lines\nThree and more"
      end
    end
  end

  describe '#basename_prefix' do
    context 'when the commit message contains non word characters' do
      let(:message) { 'Message with non->word characters!'}

      it 'strips non word characters' do
        expect(commit.basename_prefix).to eq 'message-with-non-word-characters'
      end
    end

    context 'when the commit message contains an underscore' do
      let(:message) { 'Message with an_underscore!'}

      it 'replaces underscores with dashes' do
        expect(commit.basename_prefix).to eq 'message-with-an-underscore'
      end
    end

    context 'when the commit message contains non normalized space' do
      let(:message) { 'Message with non     normalized space'}

      it 'normalizes whitespace' do
        expect(commit.basename_prefix).to eq 'message-with-non-normalized-space'
      end
    end

    context 'when the commit message contains unicode' do
      let(:message) { 'Message with unicode‽'}

      it 'removes unicode characters' do
        expect(commit.basename_prefix).to eq 'message-with-unicode'
      end
    end
  end

  describe '#filename' do
    let(:message) { 'Simple commit message' }

    it 'appends .md to the basename_prefix' do
      expect(commit.filename).to eq 'simple-commit-message.md'
    end
  end

  describe '#link' do
    let(:message) { 'Simple commit message' }

    it 'links to the filename' do
      expect(commit.link).to eq "<li><a href='simple-commit-message.html'>Simple commit message</a></li>"
    end
  end
end
