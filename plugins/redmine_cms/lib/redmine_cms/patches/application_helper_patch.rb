module RedmineCMS
  module Patches
    module ApplicationHelperPatch
      
      def self.included(base)
        base.send(:include, InstanceMethods)
      end


      module InstanceMethods
        def favicon_cms
          if current_theme && current_theme.images.include?('favicon.ico')
            "<link rel='shortcut icon' href='#{current_theme.image_path('/favicon.ico')}' />".html_safe
          else
            favicon
          end          
        end

        def jquery_tag
          if Redmine::VERSION.to_s > "2.3"
            stylesheet_link_tag 'jquery/jquery-ui-1.9.2', 'application', :media => 'all' 
          else
            stylesheet_link_tag 'jquery/jquery-ui-1.8.21', 'application', :media => 'all'
          end
        end

        def render_account_menu
          s = "<ul>"
          if User.current.logged?
            s << "<li>#{avatar(User.current, :size => "16").to_s.html_safe + link_to_user(User.current, :format => :username) }"
              # s << "<ul class=\"menu-children\">"
              links = []
              menu_items_for(:account_menu) do |node|
                links << render_menu_node(node)
              end
              s << (links.empty? ? "" : content_tag('ul', links.join("\n").html_safe, :class => "menu-children"))
              #   s << "<li>#{link_to(l(:label_cms_account_settings), { :controller => 'my', :action => 'account'})}</li>"
              #   s << "<li>#{link_to l(:label_my_page), { :controller => 'my', :action => 'page' }}</li>"
              #   s << "<li>#{link_to l(:label_logout), signout_path}</li>"
              # s << "</ul>"
            s << "</li>"
          else
            s << "<li>#{link_to l(:label_login), signin_path}</li>"
          end
          s << "</ul>"
          s.html_safe
        end

        def render_page(page)
          s = "".html_safe
          s << cached_render_part(page)
          page.pages_parts.order(:position).active.each do |pages_part|
            case pages_part.part.part_type
            when "header_tags"
              content_for(:header_tags, render_part(pages_part.part))
            when "header"
              content_for(:header, render_part(pages_part.part))
            when "sidebar"
              content_for(:sidebar, render_part(pages_part.part))
            when "footer"
              content_for(:footer, render_part(pages_part.part))
            when "content"
              s << cached_render_part(pages_part.part)
            end  
          end
          s
        end

        def cached_render_part(part)
          if part.respond_to?(:is_cached) && part.is_cached?
            Rails.cache.fetch(part, :expires_in => 15.minutes) {render_part(part)}
          else
            render_part(part)
          end
        end

        def render_part(part)
          assigns = { 'part' => part }

          registers = {
            :controller     => self,
            :part           => part
          }

          s = case part.content_type
              when "textile"
                textilizable(part, :content, :attachments => part.attachments)
              when "html"
                Liquid::Template.parse(part.content).render(Liquid::Context.new({}, assigns, registers)).html_safe 
              when "java_script"
                "<script type=\"text/javascript\">#{part.content.html_safe}</script>".html_safe 
              when "css"
                "<style type=\"text/css\">#{part.content.html_safe}</style>".html_safe 
              else
                part.content
              end 

          # (part.is_a?(Part) && ["textile", "html"].include?(part.content_type))? content_tag(:span, s, :id => part.name, :class => "part") : s
        end        

      end
      
    end
  end
end

unless ApplicationHelper.included_modules.include?(RedmineCMS::Patches::ApplicationHelperPatch)
  ApplicationHelper.send(:include, RedmineCMS::Patches::ApplicationHelperPatch)
end
