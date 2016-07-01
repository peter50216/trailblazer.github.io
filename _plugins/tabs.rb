module Jekyll
  class TabsTag < Liquid::Block
    include Liquid::StandardFilters

    def initialize(tag, tab_names, tokens)
      @id   = tokens[0].size

      super(tag, tab_names, tokens)

      @tabs = tab_names.split("|")
    end

    def render(context)
      markup = super

      blocks = markup.split("~~")
      blocks.shift

      tabs = {}
      blocks.each do |section|
        section = section.split("\n")

        tabs[section.shift] = section.join("\n")
      end

      # { Ruby: "..", Rails: "" }
      lis = tabs.keys.collect { |tab| %{<li><a href="##{@id}-#{tab}">#{tab}</a></li>} }.join("\n")
      divs = tabs.collect { |tab, content| %{<div id="#{@id}-#{tab}">#{Kramdown::Document.new(content).to_html}</div>}  }.join("\n")

      return %{
<div class="tabs">
  <ul>
    #{lis}
  </ul>
  #{divs}
</div>
      }

      # puts "@@@@@sss #{super.inspect}"
      return
    end
  end
end

Liquid::Template.register_tag('tabs', Jekyll::TabsTag)

