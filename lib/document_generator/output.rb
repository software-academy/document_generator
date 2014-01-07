module DocumentGenerator
  class Output
    attr_accessor :description, :content

    def escaped_content
      temp = []
      content.each do |line|
        temp << line
        temp << "\n"
      end

      temp.join.rstrip
    end
  end
end
