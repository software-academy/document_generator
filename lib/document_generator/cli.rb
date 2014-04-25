module DocumentGenerator
  class CLI
    def self.start(args)
      options = parse(args)

      Repository.new(options.url, options.token).generate
    end

    def self.parse(args)
      options = OpenStruct.new

      parser = OptionParser.new do |opts|
        opts.on('-u', '--url URL',
                'URL for the repository') do |url|
          options.url = url
        end
        opts.on('-t', '--token URL',
                'Token for access to github') do |token|
          options.token = token
        end
      end

      parser.parse!(args)

      # TODO: Do something better than this.
      raise OptionParser::MissingArgument unless options.url

      options
    end
  end
end
