require 'cgi'

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
        return patch_heading + "\n\n"
      end

      temp = []
      temp << "####{patch_heading}"

      if markdown_outputs.any?
        markdown_outputs.each do |output|
          if output.escaped_content.length > 0
            temp << "\n\n"
            temp << output.description
            temp << "\n<pre><code>"
            temp << output.escaped_content
            temp << "</code></pre>\n"
          end
        end
      end

      if git_diff_file.type == "modified"
        temp << "\n\n"
        temp << "Becomes"
        temp << "\n<pre><code>"
        temp << ending_code
        temp << "\n</code></pre>\n"
      end

      temp << "\n\n"

      temp.join
    end

    def ending_code
      clean_lines = []
      git_diff_file_lines[code_line_start..-1].each_with_index do |line, index|

        if (line[0]) == "-" || ignore_line?(line)
          next
        end

        if (line[0]) == "+"
          line = remove_first_character(line)
        end
        clean_lines << line
      end
      Output.no_really_escape(CGI.escapeHTML(clean_lines.join("\n")))
    end

    def action_type
      { new: 'Create file',
        modified: 'Update file',
        deleted: 'Remove file' }.fetch(type.to_sym, type)
    end

    def markdown_outputs # returns an array of outputs
      outputs = []
      last_line = 0
      git_diff_file_lines.each_with_index do |line, index|
        next if index < code_line_start
        next if index <= last_line
        case line.strip[0]

        when "+"
          last_line = last_same_line(index)
          output = Output.new
          output.description = "Add"
          output.content = line_block(index, last_line)
          outputs << output
        when "-"
          if line_sign(index + 1) == "+"
            output = Output.new
            output.description = "Change"
            output.content = line_block(index, last_same_line(index))
            outputs << output
            last_line = last_same_line(last_same_line(index) + 1)
            output = Output.new
            output.description = "To"
            output.content = line_block(last_same_line(index) + 1, last_line)
            outputs << output
          else
            output = Output.new
            output.description = "Remove"
            last_line = last_same_line(index)
            output.content = line_block(index, last_line)
            outputs << output
          end
        end

      end
      outputs
    end

  private

    def ignore_line?(line)
      line.strip == 'No newline at end of file'
    end

    def last_same_line(line_index)
      starting_sign = line_sign(line_index)

      git_diff_file_lines[line_index..-1].each_with_index do |line, index|
        if line_sign(index + 1 + line_index) != starting_sign
          return (index + line_index)
        end
      end
    end

    def line_block(beginning, ending)
      lines = []
      git_diff_file_lines[beginning..ending].each do |line|
        if ["+", "-"].include?(line[0..0])
          line = remove_first_character(line)
        end
        if !ignore_line?(line)
          lines << line
        end
      end
      lines
    end

    def line_sign(line_number)
      (git_diff_file_lines[line_number] || '').strip[0]
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
