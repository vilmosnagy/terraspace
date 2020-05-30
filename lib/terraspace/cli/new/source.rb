class Terraspace::CLI::New
  class Source
    include Helper::ProviderGem

    def initialize(sequence, options)
      @sequence, @options = sequence, options
    end

    # friendly method
    def set_source_paths(template, type)
      # project always uses the examples from the provider gem for configs
      # base always uses terraspace core templates
      # examples option always use examples from provider gems
      if (type == "project" || @options[:examples]) && template != "base"
        set_gem_source(template, type)   # provider gems has examples
      else
        set_core_source(template, type)  # terraspace core has empty starter files
      end
    end

    def set_core_source(template, type)
      template_name = template_name(template, type)
      template_path = File.expand_path("../../../templates/#{template_name}", __dir__)
      override_source_paths(template_path)
    end

    def set_gem_source(template, type)
      require_provider
      provider = Terraspace::Provider.find_with(provider: @options[:provider])
      template_name = template_name(template, type)
      template_path = File.expand_path("#{provider.root}/lib/templates/#{template_name}")
      override_source_paths(template_path)
    end

    def require_provider
      begin
        require provider_gem_name # require provider for the templates, this registers the provider
      rescue LoadError => e
        puts "#{e.class}: #{e.message}"
        puts "ERROR: Unable to require provider #{provider_gem_name}.".color(:red)
        puts "Are you sure you the provider exists and you specified the right provider option."
        puts "You specified --provider #{provider_name}"
        exit 1
      end
    end

    def override_source_paths(*paths)
      # https://github.com/erikhuda/thor/blob/34df888d721ecaa8cf0cea97d51dc6c388002742/lib/thor/actions.rb#L128
      @sequence.instance_variable_set(:@source_paths, nil) # unset instance variable cache
      # Using string with instance_eval because block doesnt have access to path at runtime.
      @sequence.class.instance_eval %{
        def self.source_paths
          #{paths.flatten.inspect}
        end
      }
    end

    def template_name(template, type)
      if template == "test"
        "#{template}/rspec/#{type}" # IE: test/rspec/module # TODO: allow testing framework to be configurable
      else
        "#{template}/#{type}"       # IE: hcl/module
      end
    end
  end
end