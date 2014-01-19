require 'redmine_cms/patches/projects_helper_patch'
require 'redmine_cms/patches/application_helper_patch'
require 'redmine_cms/patches/acts_as_attachable_patch'
require 'redmine_cms/patches/attachments_controller_patch'
require 'redmine_cms/patches/application_controller_patch'
require 'redmine_cms/patches/projects_controller_patch'
require 'redmine_cms/patches/welcome_controller_patch'
require 'redmine_cms/patches/settings_controller_patch'
require 'redmine_cms/patches/attachment_patch'

require 'redmine_cms/hooks/views_layouts_hook'
require 'redmine_cms/wiki_macros/cms_wiki_macros'

require 'liquid/tags'
require 'liquid/filters'


module RedmineCms
  
  STATUS_ACTIVE = 1
  STATUS_LOCKED = 0

  def self.settings() Setting[:plugin_redmine_cms] end
end