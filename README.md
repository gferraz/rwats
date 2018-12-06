# rwats
Rails Web Application Templates

Default Template (rwat.rb)
-----------------------------
* Locales: pt-BR
* HTML default template engine: slim
* Test: RSpec
* Deployment: mina
* API: GraphQL
* Welcome Page: pages#index
* Devlopment tools: Rubocop

Usage
-----
1. Create a new Rails application
$rails new appname
2. Run rwat template
$ rails app:template LOCATION=https://raw.githubusercontent.com/gferraz/rwats/master/rwat.rb
3. If step 3 doesn't work try:
$bundle exec rake rails:template LOCATION=https://raw.githubusercontent.com/gferraz/rwats/master/rwat.rb
4. Select the options, and wait the installation finishes.
5. Develop your application
