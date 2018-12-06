# frozen_string_literal: true

#
# Basic Rails Web Application Template
#
TEMPLATE_NAME = 'rwat'

TEMPLATE_URL = 'https://github.com/gferraz/rwats'
TEMPLATE_FILES_URL = TEMPLATE_URL + '/raw/master'
APP_VERSION = '0.0.1'

def summary(options)
  text = <<-SUMMARY
    Info
    Application: ............ #{app_name} #{APP_VERSION}
    Locales: ................ pt-BR
    Default template engine:  Slim
  SUMMARY
  text += "\n    Authentication: ......... Devise"  if options[:devise]
  text += "\n    API: .................... GraphQL" if options[:graphql]
  text += "\n    Test: ................... RSpec"   if options[:rspec]
  text += "\n    Rubocop cleanup:......... Done"    if options[:rubocop]
  text
end

def commit(message)
  git add: '.'
  git commit: %(-m '#{message}')
end

def section(title, condition = true)
  return unless condition

  dashes = '=' * (title.length + 4)
  puts
  puts dashes
  puts "  #{title}"
  puts dashes
  yield
end

options = {}

section 'Application Options' do
  options[:devise] = yes?('Use Devise? [yN]')
  options[:graphql] = yes?('Use Graphql? [yN]')
  options[:rspec] = yes?('Use RSpec? [yN]')
  options[:rubocop] = yes?('Rubocop Cleanup? [yN]')
end

section 'Baseline Commit' do
  commit 'Initial application setup'
end

section 'Install gems' do
  gem 'devise'      if options[:graphql] # Authentication (http://devise.plataformatec.com.br/)
  gem 'graphql'     if options[:graphql] # Ruby Graphql (http://graphql-ruby.org/)

  gem 'inflections' # Portuguese inflections and others (https://davidcel.is/inflections/)
  gem 'simple_form' # Rails forms made easy (https://github.com/plataformatec/simple_form)
  gem 'slim'        # lightweight templating engine (http://slim-lang.com/)
  gem 'slim-rails'  # Slim generators (https://github.com/slim-template/slim-rails)

  gem_group :development do
    gem 'erb2slim',      require: false
    gem 'graphiql-rails'
    gem 'html2slim',     require: false
    gem 'rubocop',       require: false
  end

  gem_group :test, :development do
    gem 'rspec-rails' if options[:rspec]
  end

  run_bundle
  commit 'Additional gems installed'
end

section 'Graphql Setup', options[:graphql] do
  generate 'graphql:install'
  commit 'graphql installed'
end

section 'RSpec Setup', options[:rspec] do
  generate 'rspec:install'
  commit 'Rspec installed'
end

section 'Simple Form Setup' do
  generate 'simple_form:install --bootstrap'
  commit 'Simple Form installed'
end
#
#
#  Add or replace files
#
section 'Template Files' do
  file 'CHANGELOG.md', <<~CHANGELOG
    # Change log

    ## [#{APP_VERSION}] (#{Date.current})
      ** Added Features **

      ** Fixed Issues **

  CHANGELOG

  run 'cp config/database.yml config/database.sample.yml'
  append_to_file '.gitignore', '/config/database.yml'

  #
  # Download pt-BR localization
  #
  puts '* Localization (pt-BR)'
  get 'https://github.com/svenfuchs/rails-i18n/raw/master/rails/locale/pt-BR.yml', 'config/locales/pt-BR.yml'
  commit 'Added project files'
end

#
# Application Configuration
#
section 'Slim Configuration' do
  run 'erb2slim -d app/views/layouts/*'

  generators = <<-GENERATORS

      config.generators do |g|
        g.template_engine :slim
      end
  GENERATORS
  application generators
  commit 'Slim configuration'
end

#
# Create an Welcome Page
#
section 'Welcome Page' do
  route "root :to => 'pages#index'"
  generate :controller, 'pages', 'index'

  page_file = 'app/views/pages/index.html.slim'

  prepend_to_file page_file, <<~WELCOME
    h1 #{app_name.titleize} Home Page
    p
      | Generated with Gilson Rails application template
      a(href='#{TEMPLATE_URL}') #{TEMPLATE_NAME}
      | template
    pre
      |
    #{summary(options)}
    p
      | Edit me in
      em #{page_file}
  WELCOME
  commit 'Welcome page sample added'
end

section 'Cleanup code with rubocop' do
  file '.rubocop.yml', <<~RUBOCOP
    # inherit_from: .rubocop_todo.yml

    Metrics/BlockLength:
      Exclude:
        - 'config/**/*'

    # Configuration parameters: AllowHeredoc, AllowURI, URISchemes, IgnoreCopDirectives, IgnoredPatterns.
    # URISchemes: http, https
    Metrics/LineLength:
      Exclude:
        - 'config/**/*'
      Max: 120

    Metrics/MethodLength:
      Max: 20

    Style/BlockComments:
      Exclude:
        - 'spec/spec_helper.rb'

    Style/Documentation:
      Enabled: false

  RUBOCOP
  run 'rubocop -a' if options[:rubocop]
  commit 'Rubocop'
end

#
# Print template summary
#
section 'Configuration Summary' do
  puts summary(options)
end
