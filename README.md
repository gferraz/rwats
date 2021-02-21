# rwats
Rails Web Application Templates

## Usage

 Create a new Rails application

`$ rails new appname -d postgresql`

Run rwat template

`$ rails app:template LOCATION=https:/raw.githubusercontent.com/gferraz/rwats/master/rwat.rb`

If step 3 doesn't work try:

`$ bundle exec rake rails:template LOCATION=https://raw.githubusercontent.com/gferraz/rwats/master/rwat.rb`

Select the options, and wait the installation finishes.

 Develop your application


## Features Added

### Internationalization
- pt-BR
- es (optional)

### Authentication
- Devise
- Doorkeeper

### Tools
- Rubocop
- Pry

### Other
- Slim template engine
- GraphQL API language
- Webpack

## Rails Configurations

### Asset pipeline
- Disabled sprockets
- assets removed (app, lib, vendor)
- app/javascript -> app/frontend
- images     -> app/frontend/images
- stysheets  -> app/frontend/css
- javascript -> app/frontend/js

### Aplication files

- README.md
- CHANGELOG.md
- Welcome page static#index


