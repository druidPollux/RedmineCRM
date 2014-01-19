module RedmineCMS
  module Patches
    module AttachmentPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method_chain :project, :cms
          alias_method_chain :thumbnail, :cms
        end
      end


      module InstanceMethods
        def project_with_cms
          if container.respond_to?(:project)
            container.try(:project) 
          else
            ""
          end  
        end

        def thumbnail_with_cms(options={})
          if thumbnailable? && readable?
            size = options[:size].to_i
            if size > 0
              # Limit the number of thumbnails per image
              # size = (size / 50) * 50
              # Maximum thumbnail size
              # size = 800 if size > 800
            else
              size = Setting.thumbnails_size.to_i
            end
            size = 100 unless size > 0
            target = File.join(self.class.thumbnails_storage_path, "#{id}_#{digest}_#{size}.thumb")

            begin
              Redmine::Thumbnail.generate(self.diskfile, target, size)
            rescue => e
              logger.error "An error occured while generating thumbnail for #{disk_filename} to #{target}\nException was: #{e.message}" if logger
              return nil
            end
          end
        end

        
      end
      
    end
  end
end

unless Attachment.included_modules.include?(RedmineCMS::Patches::AttachmentPatch)
  Attachment.send(:include, RedmineCMS::Patches::AttachmentPatch)
end
