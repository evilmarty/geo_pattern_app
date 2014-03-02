require 'rubygems'
require 'bundler'

Bundler.require :default, (ENV['RACK_ENV'] || 'development').to_sym

class GeoPatternApp < Sinatra::Base
  PATTERNS = GeoPattern::Pattern::PATTERNS

  if memcachier_servers = ENV['MEMCACHIER_SERVERS']
    cache = Dalli::Client.new memcachier_servers.split(','), {
      username: ENV['MEMCACHIER_USERNAME'],
      password: ENV['MEMCACHIER_PASSWORD']
    }
    use Rack::Cache, verbose: true, metastore: cache, entitystore: cache
  end

  configure :development, :production do
    enable :logging
  end

  get '/' do
    erb :index
  end

  get %r{/(#{PATTERNS.join('|')})/([0-9a-f]{6})/(\w+).svg}, provides: 'svg' do |pattern, base_color, string|
    cache_control :public, max_age: 1800

    pattern = GeoPattern.generate string, generator: pattern, base_color: base_color
    pattern.svg_string
  end

  not_found do
    erb :'404'
  end
end

