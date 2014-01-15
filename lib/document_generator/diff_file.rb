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

    def patch_heading
      "#{action_type} `#{git_diff_file.path}`"
    end

    def git_diff_file_hunks
      hunks = git_diff_file.patch.split(/@@.*@@.*\n/)
      hunks.shift # Shift to pop first element off array which is just git diff header info
      hunks
    end

    def git_diff_lines_for(hunk)
      hunk.split("\n")
    end

    def content
      if type == 'deleted'
        return "####{patch_heading}\n\n"
      end

      temp = []
      temp << "####{patch_heading}"

      outputs = markdown_outputs
      if outputs.any?
        outputs.each do |output|
          if output.escaped_content.length > 0
            temp << "\n\n"
            temp << "#####{output.description}"
            temp << "\n```\n"
            if output.description == "Becomes"
              temp << output.content.join("\n") + "\n"
            else
              temp << output.escaped_content
            end
            temp << "\n```\n"
          end
        end

      end

      temp << "\n\n"

      temp.join
    end

    def ending_code
      clean_hunks = []
      git_diff_file_hunks.each do |hunk|
        clean_hunks << ending_code_for(hunk).join("\n")
      end
      clean_hunks.join("\n")
    end

    def ending_code_for(hunk)
      clean_lines = []

      git_diff_lines_for(hunk).each_with_index do |line, index|
        if (line[0]) == "-" || ignore_line?(line)
          next
        end

        if (line[0]) == "+"
          line = remove_first_character(line)
        end
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

    def markdown_outputs_for(hunk) # returns an array of outputs for a particular hunk
      outputs = []
      last_line = -1
      git_diff_lines_for(hunk).each_with_index do |line, index|
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
        end
      end

      if git_diff_file.type == 'modified'
        output = Output.new
        output.description = "Becomes"
        output.content = ending_code_for(hunk)
        outputs << output
      end

      outputs
    end



    private

    def ignore_line?(line)
      line.strip == 'No newline at end of file'
    end

    def last_same_line(line_index, hunk)
      starting_sign = line_sign(line_index, hunk)

      git_diff_lines_for(hunk)[line_index..-1].each_with_index do |line, index|
        if line_sign(index + 1 + line_index, hunk) != starting_sign
          return (index + line_index)
        end
      end
    end

    def line_block(beginning, ending, hunk)
      lines = []
      git_diff_lines_for(hunk)[beginning..ending].each do |line|
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
      (git_diff_lines_for(hunk)[line_number] || '').strip[0]
    end

    def remove_first_character(line)
      " " + line[1..-1]
    end
  end
end
