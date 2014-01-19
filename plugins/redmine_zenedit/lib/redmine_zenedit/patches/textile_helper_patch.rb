module RedmineZenedit
  module Patches
    module TextileHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          alias_method_chain :wikitoolbar_for, :zenedit          
        end
      end


      module InstanceMethods
        def wikitoolbar_for_with_zenedit(field_id)
          heads_for_zenedit
          wikitoolbar_for_without_zenedit(field_id) + javascript_tag("jsZenEdit(document.getElementById('#{field_id}'), '#{escape_javascript "Zen"}', '#{escape_javascript l(:label_zen_placeholder)}');")
        end

        def heads_for_zenedit
          unless @heads_for_zenedit_included
            content_for :header_tags do
              javascript_include_tag(:zenedit, :plugin => 'redmine_zenedit') +
              stylesheet_link_tag(:zenedit, :plugin => 'redmine_zenedit')
            end
            @heads_for_zenedit_included = true
          end
        end

      end
      
    end
  end
end


unless Redmine::WikiFormatting::Textile::Helper.included_modules.include?(RedmineZenedit::Patches::TextileHelperPatch)
  Redmine::WikiFormatting::Textile::Helper.send(:include, RedmineZenedit::Patches::TextileHelperPatch)
end
