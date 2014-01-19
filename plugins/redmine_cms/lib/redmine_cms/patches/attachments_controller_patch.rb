module RedmineCMS
  module Patches
    module AttachmentsControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method_chain :find_project, :cms
          # skip_before_filter :find_project, :only => [:method_name]
        end
      end


      module InstanceMethods
        # include ContactsHelper

        def find_project_with_cms
          @attachment = Attachment.find(params[:id])
          # Show 404 if the filename in the url is wrong
          raise ActiveRecord::RecordNotFound if params[:filename] && params[:filename] != @attachment.filename
          @project = @attachment.project if @attachment.respond_to?(:project)
        rescue ActiveRecord::RecordNotFound
          render_404          
        end
        
      end
      
    end
  end
end

unless AttachmentsController.included_modules.include?(RedmineCMS::Patches::AttachmentsControllerPatch)
  AttachmentsController.send(:include, RedmineCMS::Patches::AttachmentsControllerPatch)
end
