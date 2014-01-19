module RedmineCms
  module Liquid
    module Tags


      class Textile < ::Liquid::Block
        include ApplicationHelper
        include ActionView::Helpers::SanitizeHelper
        def initialize(tag_name, markup, tokens)
          super
          @textile_text = markup
        end

        def render(context)
          part = context.registers[:part]
          textilizable(render_all(@nodelist, context), :attachments => part.attachments)
        end
      end  
    end
  end

  ::Liquid::Template.register_tag('textile', RedmineCms::Liquid::Tags::Textile)
end