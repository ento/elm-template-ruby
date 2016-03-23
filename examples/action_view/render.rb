require 'active_support/hash_with_indifferent_access'
require 'action_view'
require 'action_controller'
require 'haml/util'
require 'haml/template'
require_relative '../../lib/elm/renderer'

HERE = File.dirname(__FILE__)
TEMPLATE_ROOT = File.join(HERE, '..', 'views')

class ActionView::Template::Handlers::Elm
  class_attribute :default_format
  self.default_format = Mime::HTML

  def self.call(template)
     "ActionView::Template::Handlers::Elm.new(self).render(#{template.source.inspect}, local_assigns).html_safe"
  end

  def initialize(view)
    @view = view
  end

  def render(template, local_assigns = {})
    assigns = @view.assigns
    assigns.merge!(local_assigns.stringify_keys)

    Elm::Renderer.new(TEMPLATE_ROOT).render_module(template, assigns)
  end

  def compilable?
    false
  end
end

class ActionView::ElmResolver < ActionView::FileSystemResolver
  def build_query(path, details)
    query = @pattern.dup

    prefix = path.prefix.empty? ? "" : "#{escape_entry(path.prefix)}\\1"
    query.gsub!(/\:prefix(\/)?/, prefix)

    # only difference from ActionView::PathResolver:
    # - don't prepend underscore
    # - capitalize filename
    action = escape_entry(path.name.capitalize)
    query.gsub!(/\:action/, action)

    details.each do |ext, variants|
      query.gsub!(/\:#{ext}/, "{#{variants.compact.uniq.join(',')}}")
    end

    File.expand_path(query, @path)
  end
end

ActionView::Template.register_template_handler(:elm, ActionView::Template::Handlers::Elm)
ActionController::Base.prepend_view_path HERE
ActionController::Base.prepend_view_path TEMPLATE_ROOT
ActionController::Base.prepend_view_path ActionView::ElmResolver.new(TEMPLATE_ROOT)

def render(options)
  klass = Class.new(ActionView::Base)
  klass.new(ActionController::Base.view_paths).render(options)
end

puts render file: 'styleguide', layout: 'layout'
