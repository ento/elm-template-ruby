require 'sinatra'
require 'tilt'
require 'haml'
require_relative '../../lib/elm/renderer'

TEMPLATE_ROOT = File.join(File.dirname(__FILE__), '..', 'views')

class Tilt::ElmTemplate < Tilt::Template
  self.default_mime_type = 'text/html'

  def prepare
    @engine = Elm::Renderer.new(TEMPLATE_ROOT)
  end

  def evaluate(scope, locals, &block)
    @output ||= @engine.render_module(data, locals.merge(options))
  end

  def allows_script?
    false
  end
end

Tilt.register Tilt::ElmTemplate, 'elm'

helpers do
  def elm(*args)
    render(:elm, *args)
  end

  def find_template(views, name, engine, &block)
    views.each { |v| super(v, name, engine, &block) }
  end
end

configure do
  set :views, ['.', '../views']
end

get '/' do
  haml :styleguide, layout: :layout
end
