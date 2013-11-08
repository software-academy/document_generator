module DocumentGenerator
  class Repository
    attr_accessor :url

    def self.menu_dirname
      '_includes'
    end

    def self.menu_relative_filename
      File.join(menu_dirname, 'menu.md')
    end

    def self.default_dirname
      '_layouts'
    end

    def self.default_relative_filename
      File.join(default_dirname, 'default.html')
    end

    def initialize(url)
      @url = url
    end

    def base_url
      "https://#{uri.host}#{uri.path}/"
    end

    def name
      uri.path.split('/')[-1]
    end

    def generate
      prepare

      File.open(Repository.menu_relative_filename, 'w') do |menu_writer|
        commits do |commit|
          menu_writer.write(commit.link)
          commit.create
        end
      end
    end

    def commits
      Dir.mktmpdir do |path|
        repo = Git.clone(url, name, path: path)

        # TODO: Allow options to influence branch, number of commits, etc.
        repo.log(nil).reverse_each.map do |git_commit|
          yield Commit.new(base_url, git_commit)
        end
      end
    end

  private
    def prepare
      Dir.mkdir(Repository.menu_dirname) unless Dir.exists?(Repository.menu_dirname)
      copy_layout
    end

    def copy_layout
      return if File.exists?(Repository.default_relative_filename)

      Dir.mkdir(Repository.default_dirname) unless Dir.exists?(Repository.default_dirname)

      src = File.expand_path('../../../assets/_layouts/default.html', __FILE__)
      dest = Repository.default_relative_filename

      FileUtils.copy_file(src, dest)
    end

    def normalized_url
      replacements = [
        [%r(\Agit@github\.com:), 'git://github.com/'],
        [%r(\.git\Z), '']
      ]

      replacements.each do |pattern, replacement|
        url.gsub!(pattern, replacement)
      end

      url
    end

    def uri
      Addressable::URI.parse(normalized_url)
    end
  end
end
