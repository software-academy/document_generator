module DocumentGenerator
  class Output
    attr_accessor :description, :content

    # TODO: This is due to a bug in maruku.  We should create
    # an issue there--and possibly a PR to fix?
    def self.no_really_escape(value)
      value.split("\n").map do |line|
        if line.strip.size.zero?
          "&nbsp;"
        else
          line
        end
      end.join("\n")
    end

    def escaped_content
      temp = []
      content.each do |line|
        temp << line
        temp << "\n"
      end

      Output.no_really_escape(CGI.escapeHTML(temp.join.rstrip))
    end
  end
end
