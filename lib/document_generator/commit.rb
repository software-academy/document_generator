require 'net/http'
require 'json'

module DocumentGenerator
  IGNORE_DIFF_FILES = "[document_generator: skip_diff_files]"
  class Commit
    attr_accessor :base_url, :git_commit, :repo, :account_name, :access_token

    def initialize(base_url, git_commit, account_name, repo, access_token)
      @base_url = base_url
      @git_commit = git_commit
      @account_name = account_name
      @repo = repo
      @access_token = access_token
    end

    def diff_files
      return [] unless git_commit.parent

      git_commit.parent.diff(git_commit).map do |git_diff_file|
        DiffFile.new(git_diff_file)
      end
    end

    def relative_filename
      filename
    end

    def create
      File.open(relative_filename, 'w') do |writer|
        writer.write(header)
        writer.write(body_comments_markdown)

        if !skip_diff_files
          diff_files.each do |diff_file|
            writer.write(diff_file.content)
          end
        end

        writer.write(additional)
      end
    end

    def header
      <<-HEADER
---
layout: default
title: #{first_line_of_commit_message}
---

<h1 id="main">#{first_line_of_commit_message}</h1>

HEADER
    end

    def additional
      <<-ADDITIONAL

### Additional Resources

* [Changes in this step in `diff` format](#{URI.join(base_url, 'commit/', git_commit.sha)})

ADDITIONAL
    end

    def commit_github_comments
      url = "https://api.github.com/repos/#{account_name}/#{repo}/commits/#{git_commit.sha}/comments?access_token=#{access_token}"
      resp = Net::HTTP.get_response(URI.parse(url))
      data = resp.body
      comments = JSON.parse(data)
    end

    def body_comments
      comments = []

      return comments unless commit_github_comments.any?
      commit_github_comments.each do |comment|
        # Only comments on the whole commit.
        if comment["position"].nil?
          comments << comment["body"]
        end
      end
      comments
    end

    def body_comments_markdown
      body_comments.join("\n\n").sub(IGNORE_DIFF_FILES, "") + "\n"
    end

    def skip_diff_files
      return unless body_comments.any?
      ignore_commit_files = false
      body_comments.each do |comment|
        if comment.include?(IGNORE_DIFF_FILES)
          ignore_commit_files = true
        end
      end
      ignore_commit_files
    end

    def commit_message_lines
      git_commit.message.split("\n")
    end

    def first_line_of_commit_message
      commit_message_lines.first
    end

    def basename_prefix
      message = first_line_of_commit_message
      message = message.split.join('-')
      message.gsub!(%r{[^\w-]}, '')
      message.downcase!
      message.tr!('_', '-')
      message
    end

    def filename
      "#{basename_prefix}.md"
    end

    def link
      "<li><a href='#{basename_prefix}.html'>#{first_line_of_commit_message}</a></li>"
    end
  end
end
