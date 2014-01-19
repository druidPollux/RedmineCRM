require_dependency 'queries_helper'

module RedmineCms
  module Patches
    module ProjectsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          alias_method_chain :project_settings_tabs, :project_tab          
        end
      end


      module InstanceMethods
        # include ContactsHelper

        def project_settings_tabs_with_project_tab
          tabs = project_settings_tabs_without_project_tab
          tabs.push({ :name => 'project_tab',
            :action => :manage_project_tabs,
            :partial => 'projects/settings/project_tab_settings',
            :label => :label_project_tab })

          tabs.select {|tab| User.current.allowed_to?(tab[:action], @project)}
        end
        
      end
      
    end
  end
end

unless ProjectsHelper.included_modules.include?(RedmineCms::Patches::ProjectsHelperPatch)
  ProjectsHelper.send(:include, RedmineCms::Patches::ProjectsHelperPatch)
end
