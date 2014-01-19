module RedmineCms
  module WikiMacros
    
    Redmine::WikiFormatting::Macros.register do
      desc "Include page"
      macro :include_page do |obj, args|
        return "" unless obj.is_a?(Page) || obj.is_a?(Part)
        args, options = extract_macro_options(args, :parent)
        raise 'No or bad arguments.' if args.size != 1
        page = Page.find_by_name(args.first)
        raise 'Page not found' unless page
        @included_pages ||= []
        raise 'Circular inclusion detected' if @included_pages.include?(page.name)
        @included_pages << page.name
        out = render_page(page)
        @included_pages.pop
        out
      end 


      desc "Include page"
      macro :include_part do |obj, args|
        return "" unless obj.is_a?(Page) || obj.is_a?(Part)
        args, options = extract_macro_options(args, :parent)
        raise 'No or bad arguments.' if args.size != 1
        part = Part.find_by_name(args.first)
        raise 'Part not found' unless part
        @included_pages_parts ||= []
        raise 'Circular inclusion detected' if @included_pages_parts.include?(part.name)
        @included_pages_parts << part.name
        out = render_part(part)
        @included_pages_parts.pop
        out
      end 


      desc "Link to page"
      macro :page do |obj, args|
        args, options = extract_macro_options(args, :parent)
        raise 'No or bad arguments.' if args.size != 1
        page = Page.find_by_name(args.first)
        raise 'Page not found' unless page
        link_to page.title, page_path(page)
      end 

      desc "Feature with media"
      macro :feature do |obj, args, text|
        return "" unless obj.is_a?(Page) || obj.is_a?(Part)
        return "" if obj.blank?
        args, options = extract_macro_options(args, :parent, :class)
        feature_class = "feature #{options[:class] || ""}"
        # raise 'No or bad arguments.' if args.size != 1
        content = content_tag('div', textilizable(text, :object => obj, :attachments => obj.attachments), :class => "feature-content")
        content_tag('div', content, :class => feature_class)
      end 

      desc "Displays not clickable thumbnail of an attached image. Examples:\n\n<pre>{{plain_thumbnail(image.png)}}\n{{plain_thumbnail(image.png, size=300, title=Thumbnail, class=Teaser)}}</pre>"
      macro :plain_thumbnail do |obj, args|
        args, options = extract_macro_options(args, :size, :title, :class)
        filename = args.first
        raise 'Filename required' unless filename.present?
        size = options[:size]
        raise 'Invalid size parameter' unless size.nil? || size.match(/^\d+$/)
        size = size.to_i
        size = nil unless size > 0
        if obj && obj.respond_to?(:attachments) && attachment = Attachment.latest_attach(obj.attachments, filename)
          title = options[:title] || attachment.title
          img_class = options[:class] || ""
          img = image_tag(url_for(:controller => 'attachments', :action => 'thumbnail', :id => attachment, :size => size), :alt => attachment.filename, :class => img_class)
        else
          raise "Attachment #{filename} not found"
        end
      end

      desc "Page title"
      macro :page_title do |obj, args, text|
        return "" unless obj.is_a?(Page) || obj.is_a?(Part) || obj.is_a?(WikiContent) 
        return "" if obj.blank?
        args, options = extract_macro_options(args, :parent, :class)
        feature_class = "feature #{options[:class] || ""}"
        raise 'No or bad arguments.' if args.size != 1
        title = content_tag('h1', args.first)
        summary = textilizable(text, :object => obj, :attachments => obj.attachments)
        content_tag('div', title + summary, :class => "page-title").html_safe
      end

      desc "Youtube video"
      macro :youtube do |obj, args|
        args, options = extract_macro_options(args, :width, :height)
        width = options[:width] || 400
        height = options[:height] || 300
        %~
        <iframe 
          width="#{width}" 
          height="#{height}" 
          src="http://www.youtube.com/embed/#{args[0]}?hd=1" 
          frameborder="0" 
          allowfullscreen>
        </iframe>
        ~.html_safe
      end
      
      desc "Vimeo video"
      macro :vimeo do |obj, args|
        args, options = extract_macro_options(args, :width, :height)
        width = options[:width] || 400
        height = options[:height] || 300
        %~
        <iframe 
           src="http://player.vimeo.com/video/#{args[0]}?title=0&amp;byline=0&amp;portrait=0"
           width="#{width}" 
           height="#{height}" 
           frameborder="0" 
           webkitAllowFullScreen 
           mozallowfullscreen 
           allowFullScreen>
         </iframe>
        ~.html_safe
      end
      
      desc "Info block"
      macro :info do |obj, args, text|
        raise 'No or bad arguments.' if args.size < 1 && args.size > 2
        info_type = case args.first.downcase 
        when 'warning' 
          then 'warning'
        when 'error' 
          then 'error'
        else 
          'info'
        end
        content = args.second ? args.second : textilizable(text, :object => obj, :attachments => obj.attachments)

        # content = textilizable(text, :object => obj, :attachments => obj.attachments)
        content_tag('div', content, :class => "flash #{info_type}").html_safe
      end

    end  

  end
end
