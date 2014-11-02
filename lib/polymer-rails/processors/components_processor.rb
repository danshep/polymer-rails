require 'polymer-rails/component'

module Polymer
  module Rails
    class ComponentsProcessor < Sprockets::Processor

      def initialize(context, data)
        @context = context
        @component = Component.new(data)
      end

      def process
        inline_styles
        inline_javascripts
        require_imports
        @component.stringify
      end

    private

      def require_imports
        @component.imports.each do |import|
          @context.require_asset component_path(import.attributes['href'].value)
          import.remove
        end
      end

      def inline_javascripts
        @component.javascripts.each do |script|
          @component.replace_node(script, 'script', asset_content(script.attributes['src'].value))
        end
      end

      def inline_styles
        @component.stylesheets.each do |link|
          @component.replace_node(link, 'style', asset_content(link.attributes['href'].value))
        end
      end
      
      def asset_content(file)
        asset = raw_asset file
        unless asset.nil?
          asset.to_s
        else
          nil
        end
      end
      
      def raw_asset file
        raw_path = component_path(file)
        return nil if raw_path.nil?
        asset_path = ""
        ::Rails.application.assets.paths.each do |path|
          if raw_path.include? path
            r = Regexp.new "^#{path}/*"
            asset_path = raw_path.sub(r, '')
          end
        end
        ::Rails.application.assets.find_asset(asset_path.sub(/^\/*/, ''))
      end
      
      def component_path(file)
        search_file = file.sub(/^(\.\.\/)+/, '/').sub(/^\/*/, '')
        ::Rails.application.assets.paths.each do |path|
          file_list = Dir.glob( "#{File.absolute_path search_file, path }*")
          return file_list.first unless file_list.blank?
        end
        components = Dir.glob("#{File.absolute_path file, File.dirname(@context.pathname)}*")
        return components.blank? ? nil : components.first
      end

    end
  end
end
