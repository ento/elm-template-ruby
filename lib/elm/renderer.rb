require 'tempfile'
require 'json'
require 'therubyracer'
require_relative './compiler'
require_relative '../console'

HERE = File.absolute_path(File.dirname(__FILE__))

module Elm
  class Renderer
    def initialize(module_root)
      @module_root = module_root
    end

    def render_module(name_or_source, assigns)
      module_name =
        if name_or_source.is_a? String
          find_module_name(name_or_source)
        else
          name_or_source.to_s
        end
      renderer = compile_renderer(module_name)
      executor = <<-JS
#{renderer}
var elm = Elm.worker(Elm.Renderer, {
  #{model_name(module_name)}: #{JSON.generate(assigns)}
});
var value = elm.ports['#{port_name(module_name)}'];
JS

      ctx = V8::Context.new
      ctx['console'] = Console.new
      ctx.eval(executor)
      ctx[:value]
    end

    def compile_renderer(module_name)
      elm_renderer = <<-ELM
module Renderer where

import Html exposing (Html)
import Json.Encode exposing (Value)
import Json.Decode exposing (customDecoder, decodeValue, (:=))
import Json.Decode.Extra exposing ((|:))

#{generate_import(module_name)}

render : Html -> String
render = Native.Renderer.toHtml

#{generate_decoder(module_name)}
#{generate_ports(module_name)}
ELM

      temp_file = Tempfile.new ['component_renderer', '.elm']
      begin
        temp_file.write(elm_renderer)
        temp_file.rewind
        compiled_elm_renderer = Elm::Compiler.compile(temp_file.path, cwd: @module_root)
      ensure
        temp_file.close
      end
      # HACK: instead of properly importing Native.Renderer,
      # we pull it in through native_renderer.js.
      # Otherwise Native/Renderer.js must be somehow copied to
      # @module_root.
      compiled_elm_renderer.gsub!('$Native$Renderer', 'Elm.Native.Renderer.make(_elm)')

      native_renderer = File.read(File.join(HERE, '..', '..', 'assets', 'native_renderer.js'))

      <<-JS
#{compiled_elm_renderer}
#{native_renderer}
JS
    end

    def find_module_name(source)
      /^module\s+(?<module_name>[a-zA-Z0-9.]+)/.match(source)["module_name"]
    end

    def generate_ports(module_name)
      <<-ELM
port #{model_name(module_name)} : Value

port #{port_name(module_name)} : String
port #{port_name(module_name)} =
  let
    decodeResult =
      decodeValue decodeModel #{model_name(module_name)}
  in
    case decodeResult of
      Ok model ->
        #{module_name}.view model
          |> render
      Err message ->
        message
ELM
    end

    def generate_import(module_name)
      "import #{module_name} exposing (..)"
    end

    def generate_decoder(module_name)
      `python #{File.join(HERE, '..', '..', 'json-to-elm', 'generate.py')} #{module_path(module_name)}`
    end

    def module_path(module_name)
      File.join(@module_root, *module_name.split('.')) + '.elm'
    end

    def port_name(module_name)
      module_name.gsub('.', '').downcase
    end

    def model_name(module_name)
      "#{port_name(module_name)}Model"
    end

  end
end
