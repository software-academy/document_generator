# DocumentGenerator [![Build Status](https://travis-ci.org/software-academy/document_generator.png)](https://travis-ci.org/software-academy/document_generator) [![Code Climate](https://codeclimate.com/github/software-academy/document_generator.png)](https://codeclimate.com/github/software-academy/document_generator)

Generate GitHub pages from your repository's commits.

## Installation

Add this line to your application's Gemfile:

    gem 'document_generator'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install document_generator

## Usage

1.  Create an orphaned gh-pages branch (see how to [create GitHub creating project pages manually](https://help.github.com/articles/creating-project-pages-manually))

2.  Create rvm/rbenv project files

3.  Create a Gemfile and add `document_generator` to it

4.  Run the generator:

      $ bundle exec doc_generate --url URL

    where URL is your repository's URL.

## Roadmap / Issues

1.  Provide option for using a subset of the commits in a repository (it
    currently uses all commits on master)

2.  Provide option for specifying a branch (it currently uses master)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
