require 'cgi'
require 'pry'

module DocumentGenerator
  class DiffFile
    attr_accessor :git_diff_file

    def type
      git_diff_file.type
    end

    def initialize(git_diff_file)
      @git_diff_file = git_diff_file
    end

    def git_diff_file_lines
      git_diff_file.patch.split("\n")
    end

    def patch_heading
      "#{action_type} `#{git_diff_file.path}`"
    end

    def content
      if type == 'deleted'
        return "####{patch_heading}\n\n"
      end

      temp = []
      temp << "####{patch_heading}"

      # Modify markdown_outputs to include Becomes with ending_code as
      # escaped_content?
      #
      # Or try it like this (maybe refactor to the above idea after?)
      #

      if markdown_outputs.any?
        markdown_outputs.each do |output|
          if output.escaped_content.length > 0
            temp << "\n\n"
            temp << output.description
            temp << "\n<pre><code>"
            if output.description == "Becomes"
              temp << output.content.join("\n") + "\n"
            else
              temp << output.escaped_content
            end
            temp << "</code></pre>\n"
          end
        end

      end

      #if git_diff_file.type == "modified"
      #temp << "\n\n"
      #temp << "Becomes"
      #temp << "\n<pre><code>"
      #temp << ending_code
      #temp << "\n</code></pre>\n"
      #end

      temp << "\n\n"

      temp.join
    end

    def ending_code
      clean_hunks = []
      git_diff_file_hunks.each do |hunk|
        clean_lines = []

        git_diff_file_hunk_lines(hunk).each_with_index do |line, index|
          if (line[0]) == "-" || ignore_line?(line)
            next
          end

          if (line[0]) == "+"
            line = remove_first_character(line)
          end
          clean_lines << line
        end
        clean_hunks << clean_lines.join("\n")
      end
      Output.no_really_escape(CGI.escapeHTML(clean_hunks.join("\n")))
    end

    def ending_code_for(hunk) # The unescaped code for a particular hunk returned as array
      clean_lines = []

      git_diff_file_hunk_lines(hunk).each_with_index do |line, index|
        if (line[0]) == "-" || ignore_line?(line)
          next
        end

        if (line[0]) == "+"
          line = remove_first_character(line)
        end
        line = CGI.unescapeHTML(line) # Shouldn't be necessary?
        clean_lines << line
      end
      clean_lines
    end

    def action_type
      { new: 'Create file',
        modified: 'Update file',
        deleted: 'Remove file' }.fetch(type.to_sym, type)
    end

    def markdown_outputs
      outputs = []
      git_diff_file_hunks.each do |hunk|
        outputs << markdown_outputs_for(hunk)
      end
      outputs.flatten
    end

    def markdown_outputs_for(hunk) # returns an array of outputs for the particular hunk
      outputs = []
      last_line = -1
      git_diff_file_hunk_lines(hunk).each_with_index do |line, index|
        next if index <= last_line
        case line.strip[0]

        when "+"
          last_line = last_same_line(index, hunk)
          output = Output.new
          output.description = "Add"
          output.content = line_block(index, last_line, hunk)
          outputs << output
        when "-"
          if line_sign(index + 1, hunk) == "+"
            output = Output.new
            output.description = "Change"
            output.content = line_block(index, last_same_line(index, hunk), hunk)
            outputs << output
            last_line = last_same_line(last_same_line(index, hunk) + 1, hunk)

            output = Output.new
            output.description = "To"
            output.content = line_block(last_same_line(index, hunk) + 1, last_line, hunk)
            outputs << output
            last_line = last_same_line(last_same_line(index, hunk) + 1, hunk)
          else
            output = Output.new
            output.description = "Remove"
            last_line = last_same_line(index, hunk)
            output.content = line_block(index, last_line, hunk)
            outputs << output
          end

          # WTF do I put this? Gotta be easy; get it later
          if git_diff_file.type == 'modified' && done_with_changes?(last_line, hunk)
            output = Output.new
            output.description = "Becomes"
            output.content = ending_code_for(hunk)
            outputs << output
          end
        end

      end

      #if git_diff_file.type == "modified"
        #output = Output.new
        #output.description = "Becomes"
        #output.content = CGI.unescapeHTML(Output.no_really_unescape(ending_code)).split("\n")
        #outputs << output
      #end

      outputs
    end

    private

    def done_with_changes?(start_index, hunk)
      git_diff_file_hunk_lines(hunk).each_with_index do |line, index|
        next if index <= start_index
        if line.strip[0] == "-"
          false if line_sign(index + 1, hunk) == '+'
        end
      end
      true
    end

    def git_diff_file_hunks
      hunks = git_diff_file.patch.split(/@@.*@@.*\n/)
      hunks.shift # Shift to pop first element off array which is just git diff header info
      hunks
    end

    # rename git_diff_file_lines_for(hunk)
    def git_diff_file_hunk_lines(hunk)
      hunk.split("\n")
    end

    def ignore_line?(line)
      line.strip == 'No newline at end of file'
    end

    def last_same_line(line_index, hunk)
      starting_sign = line_sign(line_index, hunk)

      git_diff_file_hunk_lines(hunk)[line_index..-1].each_with_index do |line, index|
        if line_sign(index + 1 + line_index, hunk) != starting_sign
          return (index + line_index)
        end
      end
    end

    def line_block(beginning, ending, hunk)
      lines = []
      git_diff_file_hunk_lines(hunk)[beginning..ending].each do |line|
        if ["+", "-"].include?(line[0..0])
          line = remove_first_character(line)
        end
        if !ignore_line?(line)
          lines << line
        end
      end
      lines
    end

    def line_sign(line_number, hunk)
      (git_diff_file_hunk_lines(hunk)[line_number] || '').strip[0]
    end

    def remove_first_character(line)
      " " + line[1..-1]
    end

    def code_line_start
      git_diff_file_lines.each_with_index do |line, index|
        return (index + 1) if line[0..1] == "@@"
      end
    end
  end
end
