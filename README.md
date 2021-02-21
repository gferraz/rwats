# rwats
Rails Web Application Templates

## Default Template (rwat.rb)

### Features Added

- Devise and Doorkeeper
- GraphQL
- I18n 
	- pt-BR translations and inflections
- Slim template engine
- Rspec
- Template files
  - README.md
  - CHAGELOG.md
  - Welcome page (`/static/index.html`)
- Webpack
  - at `app/frontend`

### Features Removed
- Rails Asset Pipeline

### Features Considered
- Pagy
- Tailswind CSS


Usage
-----
1. Create a new Rails application
$rails new appname -d postgresql
2. Run rwat template
$ rails app:template LOCATION=https://raw.githubusercontent.com/gferraz/rwats/master/rwat.rb
3. If step 3 doesn't work try:
$bundle exec rake rails:template LOCATION=https://raw.githubusercontent.com/gferraz/rwats/master/rwat.rb
4. Select the options, and wait the installation finishes.
5. Develop your application
