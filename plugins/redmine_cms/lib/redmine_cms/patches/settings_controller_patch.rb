module RedmineCms
  module Patches    

    module SettingsControllerPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          helper :pages, :cms_menus, :cms
        end
      end
    end
    
  end
end

unless SettingsController.included_modules.include?(RedmineCms::Patches::SettingsControllerPatch)
  SettingsController.send(:include, RedmineCms::Patches::SettingsControllerPatch)
end
