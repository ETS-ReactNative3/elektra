# frozen_string_literal: true

require_relative './plugin_skeleton_generator'
require_relative './default_plugin_generator'
require_relative './react_plugin_generator'

class Generators::DashboardPlugin::DashboardPluginGenerator < Rails::Generators::NamedBase
  PLUGINS_PATH = 'plugins'

  source_root File.expand_path('../templates', __FILE__)
  class_option :mountable, type: :boolean, default: true, description: 'Generate mountable isolated application'
  class_option :service_layer, type: :boolean, default: false, description: 'Generate service layer (app/services/service_layer/)'
  class_option :react, type: :boolean, default: false, description: 'Generate plugin using react/redux js-lib'

  def start
    PluginSkeletonGenerator.new(self, PLUGINS_PATH).run

    if options.react?
      ReactPluginGenerator.new(self, PLUGINS_PATH).run
    else
      DefaultPluginGenerator.new(self, PLUGINS_PATH).run
    end
  end

  def cleanup
    Dir.glob("#{PLUGINS_PATH}/#{name}/**/*").each do |file|
      next unless File.file?(file)

      gsub_file(file, '%{PLUGIN_NAME}', name)
      gsub_file(file, '%{PLUGIN_NAME_CAMELIZE}', name.camelize)
      gsub_file(file, /\n[\n]+/, "\n\n")
    end
  end
end
