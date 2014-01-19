module RedmineCms
  module Hooks
    class ViewsLayoutsHook < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(context={})
        return stylesheet_link_tag(:cms, :plugin => 'redmine_cms') 
      end
      def view_layouts_base_body_bottom(context = { })
        return Setting.plugin_redmine_cms[:layout_content].html_safe if Setting.plugin_redmine_cms[:layout_content]
      end
    end
  end
end