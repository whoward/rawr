require 'yaml'
require 'singleton'
require 'jar_builder'

module Rawr
  class Options
    include Singleton

    def self.[](key)
      self.instance[key]
    end

    def self.load_configuration(file)
      self.instance.load_configuration file
    end


    def [](key)
      @options[key]
    end

    def load_configuration(file='build_configuration.yaml') 
      begin
        @config = YAML.load_file file
      rescue Errno::ENOENT
        @config = {}
      end

      process_configuration @config
    end


    def process_configuration(config)
      @options = {}

      @options[:project_name] = config['project_name'] || "JRuby project"
      @options[:base_dir] = Dir::pwd
      @options[:output_dir] = "#{@options[:base_dir]}/#{config['output_dir']}" || "#{@options[:base_dir]}/package"
      @options[:build_dir] = "#{@options[:output_dir]}/bin"
      @options[:package_dir] = "#{@options[:output_dir]}/deploy"

      load_ruby_options(config)
      load_java_options(config)
      load_jars_options(config)
      load_keytool_responses(config) 
      load_web_start_options(config) 
      load_jnlp(config)

    end


    def load_keytool_responses(config_hash)
      @options ||= {}
      @options[:keytool_responses] = config_hash['keytool_responses'] 

      return unless @options[:keytool_responses]
      _res = config_hash['keytool_responses'] 

      @options[:keytool_responses][:password]  = _res['password'].to_s 
      @options[:keytool_responses][:first_and_last_name]  = _res['first_and_last_name'].to_s 
      @options[:keytool_responses][:organization]  = _res['organization'].to_s 
      @options[:keytool_responses][:locality]  = _res['locality'].to_s 
      @options[:keytool_responses][:state_or_province]  = _res['state_or_province'].to_s 
      @options[:keytool_responses][:country_code]  = _res['country_code'].to_s 
      @options[:keytool_responses]
    end

    def  load_web_start_options(config_hash)
      @options ||= {}
      @options[:web_start] = config_hash['web_start'] 

      return unless @options[:web_start]

      @options[:web_start][:self_sign] =  config_hash['web_start']['self_sign'] 
      @options[:web_start][:self_sign_passphrase] =  config_hash['web_start']['self_sign_passphrase'] 
      @options[:web_start][:self_sign_passphrase] =  config_hash['web_start']['self_sign_passphrase'] 
      @options[:web_start]
    end

    def load_jnlp(config_hash)
      (@options[:jnlp] = nil; return ) unless config_hash['jnlp']

      @options[:jnlp] = {}
      @options[:jnlp][:title] =  config_hash['jnlp']['title']
      @options[:jnlp][:vendor] =  config_hash['jnlp']['vendor']
      @options[:jnlp][:codebase] =  config_hash['jnlp']['codebase']
      @options[:jnlp][:homepage_href] =  config_hash['jnlp']['homepage_href']
      @options[:jnlp][:description] =  config_hash['jnlp']['description']
      @options[:jnlp][:offline_allowed] =  config_hash['jnlp']['offline_allowed']
      @options[:jnlp][:shortcut_desktop] =  config_hash['jnlp']['shortcut_desktop']
      @options[:jnlp][:menu_submenu] =  config_hash['jnlp']['menu_submenu']
    end

    def load_ruby_options(config_hash)
      @options ||= {}
      @options[:ruby_source_dir] = "#{@options[:base_dir]}/#{config_hash['ruby_source_dir']}" || "#{@options[:base_dir]}/src"
      @options[:ruby_library_dir] = "#{@options[:base_dir]}/#{config_hash['ruby_library_dir']}" || "#{@options[:base_dir]}/lib"
      @options[:ruby_source] = config_hash['ruby_source_dir'] || "src"
      @options[:ruby_library] = config_hash['ruby_library_dir'] || "lib"
      @options[:main_ruby_file] = config_hash['main_ruby_file'] || "main"
    end

    def load_java_options(config_hash)
      @options ||= {}
      @options[:main_java_file] = config_hash['main_java_file'] || "org.rubyforge.rawr.Main"
      @options[:java_source_dir] = "#{@options[:base_dir]}/#{config_hash['java_source_dir']}" || "#{@options[:base_dir]}/src"
      @options[:classpath_dirs] = (config_hash['classpath_dirs'] || []).map {|e| "#{@options[:base_dir]}/#{e}"}
      @options[:classpath_files] = config_hash['classpath_files'] || []
      @options[:classpath] = (@options[:classpath_dirs].map{|cp| Dir.glob("#{cp}**/*.jar")} + @options[:classpath_files]).flatten
      @options[:native_library_dirs] = (config_hash['native_library_dirs'] || []).map {|e| "#{@options[:base_dir]}/#{e}"}
      @options[:jar_data_dirs] = config_hash['jar_data_dirs'] || []
      @options[:package_data_dirs] = config_hash['package_data_dirs'] || []
    end

    def load_jars_options(config_hash)
      @options ||= {}
      @options[:classpath] ||= []
      @options[:jars] = {}
      jars_hash = config_hash['jars'] || {}
      jars_hash.each do |name, jar_options|
        jar_dir = jar_options['dir'] || '/'
        jar_dirs = [jar_dir] unless jar_dir.kind_of? Array

        jar_glob = jar_options['glob'] || '**/*'
        jar_globs = [jar_glob] unless jar_glob.kind_of? Array

        jar_builder = JarBuilder.new
        jar_builder.name = name
        jar_builder.dirs = jar_dirs
        jar_builder.globs = jar_globs

        @options[:jars][name] = jar_builder
        @options[:classpath] << jar_builder.name
      end
    end

  end
end
