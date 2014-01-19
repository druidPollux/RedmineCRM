module RedmineCms
  module Liquid
    module Filters
      include ApplicationHelper
      include Rails.application.routes.url_helpers

      def textilize(input)
        RedCloth3.new(input).to_html
      end

      def attachment_url(input)
        return '' if input.nil?
        part, filename = get_part(input)
        attachment = part.attachments.where(:filename => filename).first
        attachment ? "/attachments/download/#{attachment.id}/#{attachment.filename}" : "attachment #{filename} not found"
      end

      # example:
      #   {{ 'image.png' | thumbnail_url: 'size:100' }}
      def thumbnail_url(input, *args)
        return '' if input.nil?
        options = args_to_options(args)
        size   = options[:size] || '100'
        ss.match(/(^\S+):/)
        part, filename = get_part(input)
        attachment = part.attachments.where(:filename => filename).first
        attachment ? "/attachments/thumbnail/#{attachment.id}/#{size}" : "attachment #{filename} not found"
      end  

      # example:
      #   {{ 'image.png' | thumbnail_tag: 'size:100', 'title:A title', 'width:100px', 'height:200px'  }}
      def thumbnail_tag(input, *args)
        return '' if input.nil?
        image_options = inline_options(args_to_options(args))
        options = args_to_options(args)
        size   = options[:size] || '100'
        part, filename = get_part(input)
        attachment = part.attachments.where(:filename => filename).first
        attachment ? "<img src=\"/attachments/thumbnail/#{attachment.id}/#{size}\" #{image_options}/>"  : "attachment #{filename} not found"
      end   

      # example:
      #   {{ 'image.png' | fancybox_tag: 'size:100', 'title:A title', 'width:100px', 'height:200px'  }}
      def fancybox_tag(input, *args)
        return '' if input.nil?
        image_options = inline_options(args_to_options(args))
        options = args_to_options(args)
        size   = options[:size] || '100'
        # part, filename = get_part(input)
        # attachment = part.attachments.where(:filename => filename).first
        "<a rel=\"fancybox_group\" href=\"#{attachment_url(input)}\" title=\"#{options[:title]}\">#{thumbnail_tag(input, *args)}</a><p>#{options[:title]}</p>"
      end    

      # example:
      #   {{ 'image.png' | asset_image_tag: 'title:A title', 'width:100px', 'height:200px'  }}
      def asset_image_tag(input, *args)
        return '' if input.nil?
        image_options = inline_options(args_to_options(args))
        options = args_to_options(args)
        "<img src=\"/plugin_assets/redmine_cms/images/#{input}\" #{image_options}/>" 
      end      

    protected  

      # Convert an array of properties ('key:value') into a hash
      # Ex: ['width:50', 'height:100'] => { :width => '50', :height => '100' }
      def args_to_options(*args)
        options = {}
        args.flatten.each do |a|
          if (a =~ /^(.*):(.*)$/)
            options[$1.to_sym] = $2
          end
        end
        options
      end

      # Write options (Hash) into a string according to the following pattern:
      # <key1>="<value1>", <key2>="<value2", ...etc
      def inline_options(options = {})
        return '' if options.empty?
        (options.stringify_keys.sort.to_a.collect { |a, b| "#{a}=\"#{b}\"" }).join(' ') << ' '
      end

      def get_part(input)
        if m = input.match(/(^\S+):(.+)$/)
          part = Part.find_by_name(m[1])
          filename = m[2]
        end
        part ||= @context.registers[:part]
        filename ||= input
        [part, filename]
      end

    end
  end

  ::Liquid::Template.register_filter(RedmineCms::Liquid::Filters)  
end