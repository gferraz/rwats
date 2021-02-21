#
# Basic Rails Web Application Template
#
TEMPLATE_URL = 'https://github.com/gferraz/rwats'.freeze
TEMPLATE_NAME = 'rwat'.freeze
APP_VERSION = '0.0.1'.freeze

SETUP = {
  application: "#{app_name} #{APP_VERSION}",
  api: 'none',
  authentication: 'none',
  frontend: 'Asset Pipeline',
  gems: [],
  locales: ['pt-BR'],
  template_engines: ['erb, slim'],
  test: 'minitest'
}.freeze

class GemList
  Gem = Struct.new(:name, :package, :options)

  attr_reader :gems

  def initialize(package)
    @package = package
    @gems = []
  end

  def add(name, options = {})
    gem = Gem.new name, @package, options
    @gems << gem
    gem
  end
end

class Package
  attr_accessor :name, :desc
  attr_writer :optional

  def initialize(name)
    @name = name
    @gem_list = GemList.new(self)
    @installed = false
    @optional = false
  end

  def gems
    yield @gem_list if block_given?
    @gem_list.gems
  end

  def install(&block)
    @script = block
  end

  def install!
    if installed?
      say "#{name} already installed.", :blue
    else
      puts "Installing #{name} script"
      @script&.call
      @installed = true
    end
  end

  def installed?
    @installed
  end

  def required?
    !@optional
  end
end

class Application
  attr_reader :name, :packages

  def initialize(name)
    @name = name
    @packages = []
  end

  def package(name)
    package = packages.detect { |p| p.name == name }
    package ||= Package.new(name)
    yield package if block_given?
    @packages << package
    package
  end

  def required_packages
    packages.select(&:required?)
  end

  def gems(packages)
    packages.collect(&:gems).flatten.uniq(&:name)
  end

  def installed_gems
    gemfile = File.read 'Gemfile'
    gems(packages).select do |g|
      found = gemfile.scan /^\s*gem\s+['"]#{g.name}['"]/
      found.any?
    end
  end

  def gems_to_install(packages)
    gems(packages) - installed_gems
  end

  def install!(packages)
    packages.each(&:install!)
  end
end

app = Application.new(app_name)

app.package(:devise) do |pack|
  pack.desc = 'Devise authetication with doorkeper and i18n'
  pack.optional = true
  pack.gems do |gem|
    gem.add 'devise'
    gem.add 'devise-i18n'
    gem.add 'devise-doorkeeper'
  end

  pack.install do
    generate 'devise:install'
  end
end

app.package(:graphql) do |pack|
  pack.desc = 'GraphQL API query language'
  pack.optional = true
  pack.gems do |gem|
    gem.add 'graphql'
  end
  pack.install do
    generate 'graphql:install'
  end
end

app.package(:minitest) do |pack|
  pack.desc = 'Minitest test framework'
  pack.optional = true
  pack.gems do |gem|
    gem.add 'minitest-rails',    group: %i[development test]
    gem.add 'factory_bot_rails', group: %i[development test]
    gem.add 'rubocop-minitest',  group: %i[development test], require: false
  end
end

app.package(:pt_br) do |pack|
  pack.desc = 'i18n Localization: pt-BR'
  pack.gems do |gem|
    gem.add 'inflections'
  end
  pack.install do
    get 'https://github.com/svenfuchs/rails-i18n/raw/master/rails/locale/pt-BR.yml', 'config/locales/pt-BR.yml'
  end
end

app.package(:rspec) do |pack|
  pack.desc = 'Rspec test framework, along Factory Bot'
  pack.optional = true
  pack.gems do |gem|
    gem.add 'rspec-rails',       group: %i[development test]
    gem.add 'factory_bot_rails', group: %i[development test]
    gem.add 'rubocop-rspec',     group: %i[development test], require: false
  end
  pack.install do
    generate 'rspec:install'
  end
end

app.package(:rubocop) do |pack|
  pack.desc = 'Rubocop code linter'
  pack.gems do |gem|
    gem.add 'rubocop',          require: false
    gem.add 'rubocop-rails',    require: false
  end
  pack.install do
    run 'rubocop -a'
  end
end

app.package(:slim) do |pack|
  pack.desc = 'Slim HTML template'
  pack.gems do |gem|
    gem.add 'slim'
    gem.add 'slim-rails'
    gem.add 'erb2slim',  require: false, group: :development
    gem.add 'html2slim', require: false, group: :development
  end
  pack.install do
    say 'Convert erb scripts to slim'
    run 'erb2slim -d app/views/layouts/*.html.erb'
  end
end

app.package(:webpack) do |pack|
  pack.desc = 'Webpack'
  pack.gems do |gem|
    gem.add 'webpacker'
  end
  pack.install do
    rails_command 'webpacker:install'

    gsub_file 'config/webpacker.yml', 'app/javascript', 'app/frontend', force: true
    run 'mv app/javascript app/frontend'
    remove_dir 'app/assets'
    remove_dir 'lib/assets'
    remove_dir 'vendor/assets'
  end
end

def commit(message)
  git add: '.'
  git commit: %(-m '#{message}')
end

def summary
  sum = SETUP.collect do |attribute, value|
    attribute = attribute.name.titleize
    val = value.is_a?(Array) ? value.join(', ') : value.to_s
    dots = '.' * (60 - attribute.size - val.size)
    "#{attribute}: #{dots} #{val}"
  end
  sum.join("\n")
end

def yaml(path)
  yaml = YAML.safe_load File.read path
  new_yaml = yaml.deep_dup
  yield new_yaml
  if yaml == new_yaml
    say "identical #{path}.", :blue
  else
    File.write path, new_yaml
    say "#{path} updated.", :green
  end
end

def replace(path, old_text, new_text)
  content = File.read path
  new_content = content.gsub old_text, new_text
  if content == new_content
    say "identical #{path}.", :blue
  else
    File.write path, new_content
    say "#{path} updated.", :green
  end
end

def section(title)
  dashes = '=' * 40
  puts
  say dashes
  say "  #{title}"
  say dashes
  puts
  yield
end

def template_file_url(template)
  "https://raw.githubusercontent.com/gferraz/rwats/master/templates/#{template}"
end

def selected_packages
  @selected_packages ||= []
end

section 'Application setup selection' do
  puts 'Available packages'
  puts '------------------'
  app.packages.each do |pack|
    say "  #{pack.name}: \t#{pack.desc}"
  end
  puts
  if yes? 'Select optional packages? [yN]'
    puts
    selected_packages << :devise  if yes?('Authetication with Devise? [yN]')
    selected_packages << :graphql if yes?('API with Graphql? [yN]')
  end
  selected_packages << (yes?('Tests with RSpec? [yN]') ? :rspec : :minitest)
  puts '--------------------------------'
  puts 'Packages to be installed'
  say app.required_packages.map(&:name).join(',')
  say selected_packages.join(', '), :yellow
  next if yes?('Confirm and continue?')

  say 'Nothing installed. Thanks. Good bye', :blue
  exit
end

section 'Install gems' do
  selected = selected_packages.map { |name| app.package(name) }
  gems = app.gems_to_install(app.required_packages + selected)

  if gems.any?
    gems.each do |gem|
      gem gem.name, gem.options
    end
    run_bundle
    commit "Additional gems installed: #{gems.map(&:name).join(', ')}"
  else
    say 'No new gems were added.', :blue
  end
  say 'Gems instalation complete', :green
end

section 'Install Packages' do
  selected = selected_packages.map { |name| app.package(name) }
  app.install!(app.required_packages)
  app.install!(selected)
end

#  Add or replace files
#
section 'Template Files' do
  get template_file_url('README.md'),    'README.md',    force: true
  get template_file_url('CHANGELOG.md'), 'CHANGELOG.md', force: true
  gsub_file 'CHANGELOG.md', /<version> \(<release date>\)/, "#{APP_VERSION} (#{Date.today})"
end

#
# Application Configuration
#

section 'Update Application generators configuration' do
  config = {
    assets: false,
    template_engine: ':slim',
    scaffold_stylesheet: false
  }

  generators = config.collect { |key, value| "    config.generators.#{key} #{value}" }
  application generators.join("\n")
  commit 'Application Generators config updated'
end

#
# Create an Welcome Page
#
section 'Welcome Page' do
  route "root :to => 'static#index'"
  generate :controller, 'static', 'index', '--skipe-assets', '--skip-collision-check'

  page_file = 'app/views/static/index.html.slim'

  prepend_to_file page_file, <<~WELCOME
    h1 #{app_name.titleize} Home Page
    p
      | Generated with Rails web application template (rwat)
      a(href='#{TEMPLATE_URL}') #{TEMPLATE_NAME}
      | template
    pre
      |
    #{summary.join("\n")}
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
  run 'rubocop -a' if selected_packages[:rubocop]
  commit 'Rubocop run'
end

#
# Print template summary
#
section 'Configuration Summary' do
  puts summary
end
