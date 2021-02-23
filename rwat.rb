#
# Basic Rails Web Application Template
#

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

  def initialize(name)
    @name = name
    @gem_list = GemList.new(self)
    @installed = false
  end

  def gems
    yield @gem_list if block_given?
    @gem_list.gems
  end

  def install(&block)
    @script = block
  end

  def install!
    puts '-----------------------------'
    puts "Installing #{name} - #{desc}"

    if installed?
      status = 'previously installed'
    elsif skip?
      status = 'skipped'
    else
      @script&.call
      @installed = true
      status = 'installed'
    end
    puts "  #{name} #{status}"
    puts '-----------------------------'
  end

  def installed?
    @installed
  end

  def skip?
    !!@skip&.call
  end

  def skip_if(&block)
    @skip = block
  end
end

class Application
  attr_reader :name, :packages, :version

  def initialize(name, options: {})
    @name = name
    @packages = []
    @version = options[:version] || '0.0.1'
  end

  def package(name)
    package = packages.detect { |p| p.name == name }
    package ||= Package.new(name)
    yield package if block_given?
    @packages << package
    package
  end

  def gems(packages)
    packages.collect(&:gems).flatten.uniq(&:name)
  end

  def configure(packages_names)
    selected_packages = packages_names.map { |name| package(name) }
    @packages_to_install = packages_to_install + selected_packages
    @packages_to_install.uniq!
  end

  def configuration
    packages_to_install.map(&:name)
  end

  def packages_to_install
    @packages_to_install || []
  end

  def included?(_name)
    !!packages_to_install.detect(&:name)
  end

  def gems_to_install
    gemfile = File.read 'Gemfile'
    selection  = gems(packages_to_install)
    selection.reject { |g| gemfile.scan(/^\s*gem\s+['"]#{g.name}['"]/).any? }
  end

  def install!
    packages_to_install.each(&:install!)
  end

  def installed_packages
    packages.select(&:installed?)
  end
end

app = Application.new(app_name)


app.package(:action_policy) do |pack|
  pack.desc = 'Action Policy authorization'
  pack.skip_if { File.exist? 'app/policies' }
  pack.gems do |gem|
    gem.add 'action_policy'
  end
  pack.install do
    generate 'action_policy:install'
  end
end

app.package(:devise) do |pack|
  pack.desc = 'Devise authetication with doorkeper and i18n'
  pack.skip_if { File.exist? 'config/initializers/devise.rb' }
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
  pack.skip_if { File.exist? 'app/graphql' }
  pack.gems do |gem|
    gem.add 'graphql'
    gem "action_policy-graphql"
  end
  pack.install do
    generate 'graphql:install'
  end
end

app.package(:minitest) do |pack|
  pack.desc = 'Minitest test framework'
  pack.gems do |gem|
    gem.add 'minitest-rails',    group: %i[development test]
    gem.add 'factory_bot_rails', group: %i[development test]
    gem.add 'rubocop-minitest',  group: %i[development test], require: false
  end
end

app.package(:pt_br) do |pack|
  pack.desc = 'i18n Localization: pt-BR'
  pack.skip_if { File.exist? 'config/locales/pt-BR.yml' }
  pack.gems do |gem|
    gem.add 'inflections'
  end
  pack.install do
    get 'https://github.com/svenfuchs/rails-i18n/raw/master/rails/locale/pt-BR.yml', 'config/locales/pt-BR.yml'
  end
end

app.package(:rspec) do |pack|
  pack.desc = 'Rspec test framework, along Factory Bot'
  pack.skip_if { File.exist? '.rspec' }
  pack.gems do |gem|
    gem.add 'rspec-rails',       group: %i[development test]
    gem.add 'factory_bot_rails', group: %i[development test]
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
    gem.add 'rubocop-minitest', group: %i[development test], require: false if app.included? :minitest
    gem.add 'rubocop-rspec',    group: %i[development test], require: false if app.included? :rspec
  end
  pack.install do
    get template_file_url('.rubocop.yml'), '.rubocop.yml'
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
    application '    config.generators.template_engine :slim'
    # TODO: Not working
    #say 'Convert erb scripts to slim'
    #run 'erb2slim -d app/views/layouts/*.html.erb'
  end
end

app.package(:webpack) do |pack|
  pack.desc = 'Webpack'
  pack.skip_if { File.exist? 'config/webpacker.yml' }
  pack.gems do |gem|
    gem.add 'webpacker'
  end
  pack.install do
    rails_command 'webpacker:install'
    # application '    config.generators.assets false'
    # application '    config.generators.scaffold_stylesheet false'
    # gsub_file 'config/webpacker.yml', 'app/javascript', 'app/frontend', force: true
    # run 'mv app/javascript app/frontend'
    # empty_directory 'app/frontend/assets'
    # empty_directory 'app/frontend/src'
    # empty_directory 'app/frontend/vendor'
    # remove_dir 'app/assets'
    # remove_dir 'lib/assets'
    # remove_dir 'vendor/assets'
  end
end

app.package(:tailwind) do |pack|
  pack.desc = 'Tailwind CSS'
  pack.gems do |gem|
    gem.add 'tailwindcss-rails'
  end
  pack.install do
    rails_command 'tailwindcss:install:webpacker'
  end
end

app.package(:docs) do |pack|
  pack.desc = 'Add README and CHANGELOG'
  pack.skip_if { File.exist? 'CHANGELOG.md' }
  pack.install do
    get template_file_url('README.md'),    'README.md',    force: true
    get template_file_url('CHANGELOG.md'), 'CHANGELOG.md', force: true
    gsub_file 'CHANGELOG.md', /<version> \(<release date>\)/, "#{app.version} (#{Date.today})"
  end
end

def commit(message)
  git add: '.'
  git commit: %(-m '#{message}')
end

def yaml(path)
  yaml = YAML.safe_load File.read path
  new_yaml = yaml.deep_dup
  yield new_yaml
  if yaml == new_yaml
    say "identical #{path}.", :cyan
  else
    File.write path, new_yaml
    say "#{path} updated.", :green
  end
end

def file_contains?(path, text)
  content = File.read path
  found = File.read(path).scan(text)
  found.any?
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

section 'Application setup selection' do
  say 'Available packages'
  say '------------------'
  app.packages.each do |pack|
    say "  #{pack.name}: \t#{pack.desc}"
  end
  say
  say 'Default packages'
  say '----------------'
  app.configure %i[action_policy docs pt_br rubocop slim webpack tailwind]
  app.packages_to_install.each do |pack|
    say "  #{pack.name}: \t#{pack.desc}"
  end
  say
  selected_packages = []
  if yes? 'Add optional packages? [yN]'
    selected_packages << :devise  if yes?('  Authentication with Devise? [yN]')
    selected_packages << :graphql if yes?('  API with Graphql? [yN]')
  end
  selected_packages << (yes?('  Tests with RSpec? [yN]') ? :rspec : :minitest)
  puts '--------------------------------'
  app.configure selected_packages

  say "Packages to set up: #{app.configuration.join(', ')}", :cyan
  next if yes?('Confirm and continue?')

  say 'Nothing installed. Thanks. Good bye', :cyan
  exit
end

section 'Install gems' do
  gems = app.gems_to_install
  if gems.any?
    gems.each do |gem|
      gem gem.name, gem.options
    end
    run_bundle
    commit "Additional gems installed: #{gems.map(&:name).join(', ')}"
  else
    say 'No new gems were added.', :cyan
  end
  say 'Gems instalation complete', :green
end

section 'Install Packages' do
  app.install!
  say '-' * 40, :yellow
  commit "#{app.installed_packages.map(&:name)} Installed"
end

#
# Create an Welcome Page
#
section 'Welcome Page' do
  if file_contains?('config/routes.rb', /static.index/)
    say 'static/index page already exists', :cyan
    next
  end
  generate :controller, 'static', 'index', '--skipe-assets', '--skip-collision-check'

  page_file = 'app/views/static/index.html.slim'

  prepend_to_file page_file, <<~WELCOME
    h1 #{app_name.titleize} Home Page
    p
      | Generated with Rails web application
      a href='https://github.com/gferraz/rwats' rwat template
    pre Summary
    p
      | Edit me in
      em #{page_file}
  WELCOME

  route "root :to => 'static#index'"

  commit 'Welcome page sample added'
end

section 'Rubocop add test plugins and run' do
  if app.package(:minitest).installed?
    insert_into_file '.rubocop.yml',  "  - rubocop-minitest\n", after: "require:\n"
  elsif app.package(:rspec).installed?
    insert_into_file '.rubocop.yml',  "  - rubocop-rspec\n", after: "require:\n"
  end
  run 'rubocop -a --auto-gen-config'
  commit 'Rubocop first run'
end
