
module CORL
module Util
module Puppet
class Resource < Core

  include Mixin::SubConfig

  #-----------------------------------------------------------------------------
  # Constructor / Destructor

  def initialize(group, info, title, properties = {})
    super({
      :group => group,
      :title => string(title),
      :info  => symbol_map(hash(info)),
      :ready => false
    }, {}, true, true, false)

    import(properties)
  end

  #-----------------------------------------------------------------------------
  # Property accessors / modifiers

  def group
    return _get(:group)
  end

  #---

  def info(default = {})
    return hash(_get(:info, default))
  end

  #---

  def info=info
    _set(:info, hash(info))
  end

  #---

  def title(default = '')
    return string(_get(:title, default))
  end

  #---

  def title=info
    _set(:title, string(info))
  end

  #---

  def ready(default = false)
    return test(_get(:ready, default))
  end

  #---

  def defaults(defaults, options = {})
    super(defaults, options)

    _set(:ready, false)
    return self
  end

  #---

  def import(properties, options = {})
    super(properties, options)

    _set(:ready, false)
    return self
  end

  #-----------------------------------------------------------------------------
  # Resource operations

  def ensure_ready(options = {})
    unless ready
      process(options)
    end
  end

  #---

  def process(options = {})
    config = Config.ensure(options)

    tag(config[:tag])
    render(config)
    translate(config)

    _set(:ready, true) # Ready for resource creation
    return self
  end

  #---

  def tag(tags, append = true)
    unless Data.empty?(tags)
      if tags.is_a?(String)
        tags = tags.to_s.split(/\s*,\s*/)
      else
        tags = tags.flatten
      end
      resource_tags = get(:tag)

      if ! resource_tags || ! append
        set(:tag, tags)
      else
        tags.each do |tag|
          resource_tags << tag unless resource_tags.include?(tag)
        end
        set(:tag, resource_tags)
      end
    end
    return self
  end

  #---

  def self.render(resource_info, options = {})
    resource = string_map(resource_info)
    config   = Config.ensure(options)

    resource.keys.each do |name|
      if match = name.to_s.match(/^(.+)_template$/)
        target = match.captures[0]

        config.set(:normalize_template, config.get("normalize_#{target}", true))
        config.set(:interpolate_template, config.get("interpolate_#{target}", true))

        input_data       = resource[target]
        resource[target] = CORL.template(config, resource[name]).render(input_data)

        if config.get(:debug, false)
          CORL.ui.info("\n", { :prefix => false })
          CORL.ui_group("#{resource[name]} template", :cyan) do |ui|
            ui.info("-----------------------------------------------------")

            source_dump  = Console.blue(Data.to_json(input_data, true))
            value_render = Console.green(resource[target])

            ui.info("Data:\n#{source_dump}")
            ui.info("Rendered:\n#{value_render}")
            ui.info("\n", { :prefix => false })
          end
        end
        resource.delete(name)
      end
    end
    return resource
  end

  #---

  def render(options = {})
    resource = self.class.render(export, options)
    clear
    import(Config.ensure(resource).export, options)
    return self
  end

  #---

  def translate(options = {})
    config = Config.ensure(options)

    set(:before, translate_resource_refs(get(:before), config)) if get(:before)
    set(:notify, translate_resource_refs(get(:notify), config)) if get(:notify)
    set(:require, translate_resource_refs(get(:require), config)) if get(:require)
    set(:subscribe, translate_resource_refs(get(:subscribe), config)) if get(:subscribe)

    return self
  end

  #-----------------------------------------------------------------------------
  # Utilities

  def translate_resource_refs(resource_refs, options = {})
    return :undef if Data.undef?(resource_refs)

    config         = Config.ensure(options)
    resource_names = config.get(:resource_names, {})
    title_prefix   = config.get(:title_prefix, '')

    title_pattern  = config.get(:title_pattern, '^\s*([^\[\]]+)\s*$')
    title_group    = config.get(:title_var_group, 1)
    title_flags    = config.get(:title_flags, '')
    title_regexp   = Regexp.new(title_pattern, title_flags.split(''))

    allow_single   = config.get(:allow_single_return, true)

    type_name      = info[:name].sub(/^\@?\@/, '')
    values         = []

    composite_resources = group.composite_resources

    case resource_refs
    when String
      if resource_refs.empty?
        return :undef
      else
        resource_refs = resource_refs.split(/\s*,\s*/)
      end

    when ::Puppet::Resource
      resource_refs = [ resource_refs ]
    end

    resource_refs.collect! do |value|
      if value.is_a?(::Puppet::Resource) || ! value.to_s.match(title_regexp)
        value.to_s

      elsif resource_names.has_key?(value.to_sym)
        if ! title_prefix.empty?
          "#{title_prefix}_#{value}"
        else
          value.to_s
        end

      elsif composite_resources.has_key?(value.to_sym) && ! composite_resources[value.to_sym].empty?
        results = []
        composite_resources[value.to_sym].each do |resource_name|
          unless title_prefix.empty?
            resource_name = "#{title_prefix}_#{resource_name}"
          end
          results << resource_name
        end
        results

      else
        nil
      end
    end

    resource_refs.flatten.each do |ref|
      unless ref.nil?
        unless ref.is_a?(::Puppet::Resource)
          ref = ref.match(title_regexp) ? ::Puppet::Resource.new(type_name, ref) : ::Puppet::Resource.new(ref)
        end
        values << ref unless ref.nil?
      end
    end

    return values[0] if allow_single && values.length == 1
    return values
  end
  protected :translate_resource_refs
end
end
end
end

