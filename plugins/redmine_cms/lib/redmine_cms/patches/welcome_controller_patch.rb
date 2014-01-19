module RedmineCms
  module Patches
    module WelcomeControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          caches_action :sitemap, :expires_in => 1.week
          alias_method_chain :index, :cms
        end
      end

      module InstanceMethods

        def index_with_cms
          unless RedmineCms.settings[:landing_page].blank?
            redirect_to RedmineCms.settings[:landing_page], :status => 301
          else
            index_without_cms
          end
        end

        def sitemap
          @projects = Project.all_public.active
          @pages = Page.active.all
          respond_to do |format|
            format.xml
          end
        end        
        
      end

    end
  end
end

unless WelcomeController.included_modules.include?(RedmineCms::Patches::WelcomeControllerPatch)
  WelcomeController.send(:include, RedmineCms::Patches::WelcomeControllerPatch)
end