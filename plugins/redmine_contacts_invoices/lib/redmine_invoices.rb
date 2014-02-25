# This file is a part of Redmine Invoices (redmine_contacts_invoices) plugin,
# invoicing plugin for Redmine
#
# Copyright (C) 2011-2013 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_contacts_invoices is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts_invoices is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts_invoices.  If not, see <http://www.gnu.org/licenses/>.

Rails.configuration.to_prepare do

  require 'redmine_invoices/hooks/views_layouts_hook'
  require 'redmine_invoices/hooks/controller_contacts_duplicates_hook'

  require 'redmine_invoices/patches/application_helper_patch'
  require 'redmine_invoices/patches/project_patch'
  require 'redmine_invoices/patches/contact_patch'
  require 'redmine_invoices/patches/add_helpers_for_invoices_patch'
end

require 'reports/invoice_reports'

require 'redmine_invoices/liquid/invoices'

class InvoicesSettings
  MACRO_LIST = %w({%contact.first_name%} {%contact.last_name%} {%contact.name%} {%contact.company%} {%invoice.number%} {%invoice.invoice_date%} {%invoice.due_date%} {%invoice.public_link%})

  # Returns the value of the setting named name
  def self.[](name, project_id)
    project_id = project_id.id if project_id.is_a?(Project)
    contacts_setting = ContactsSetting[name, project_id]
    contacts_setting.blank? ? Setting.plugin_redmine_contacts_invoices[name.to_s] : contacts_setting
  end

  def self.disable_taxes?(project_id = nil)
    contacts_setting = ContactsSetting["disable_taxes", project_id]
    contacts_setting.blank? ? ContactsSetting.disable_taxes? : contacts_setting.to_i > 0
  end

  def self.email_from_address
    if Setting.plugin_redmine_contacts_invoices["invoices_email_current_user"].to_i > 0
      User.current.logged? ? "#{User.current.name} <#{User.current.mail}>" : Setting.mail_from
    else
      Setting.plugin_redmine_contacts_invoices["invoices_email_from_address"].blank? ? Setting.mail_from : Setting.plugin_redmine_contacts_invoices["invoices_email_from_address"]
    end
  end

  def self.default_list_style
    Setting.plugin_redmine_contacts_invoices["invoices_excerpt_invoice_list"].to_i > 0 ? 'list_excerpt' : 'list'
  end

  def self.show_units?(project_id = nil)
    !!Setting.plugin_redmine_contacts_invoices["show_units"]
  end

  def self.custom_template(project_id = nil)
    InvoicesSettings["invoices_custom_template", project_id]
  end

  def self.template(project_id = nil)
    InvoicesSettings["invoices_template", project_id]
  end


  def self.is_custom_template?(project_id = nil)
    InvoicesSettings.template(project_id) == RedmineInvoices::TEMPLATE_CUSTOM
  end

  def self.public_links?
    !!Setting.plugin_redmine_contacts_invoices["invoices_public_links"]
  end

end

module RedmineInvoices

  TEMPLATE_CLASSIC = "classic"
  TEMPLATE_MODERN = "modern"
  TEMPLATE_MODERN_LEFT = "modern_left"
  TEMPLATE_BLANK_HEADER = "modern_blank_header"
  TEMPLATE_CUSTOM = "custom"

  def self.settings() Setting[:plugin_redmine_contacts_invoices].blank? ? {} : Setting[:plugin_redmine_contacts_invoices]  end

  def self.invoice_lines_units
    settings[:invoices_units].blank? ? [] : settings[:invoices_units].split("\n")
  end

  def self.available_locales
    Dir.glob(File.join(Redmine::Plugin.find(:redmine_contacts_invoices).directory, 'config', 'locales', '*.yml')).collect {|f| File.basename(f).split('.').first}.collect(&:to_sym)
    # [:en, :de, :fr, :ru]
  end

  def self.rate_plugin_installed?
    @@rate_plugin_installed ||= Redmine::Plugin.installed?(:redmine_rate)
  end

  def self.default_user_rate(user, project)
    if RedmineInvoices.rate_plugin_installed? && InvoicesSettings["invoices_use_rate_plugin", project]
       Rate.find(:first,
                 :conditions => {:project_id => project.id, :user_id => user.id},
                 :order => "#{Rate.table_name}.date_in_effect ASC").try(:amount).to_s
    else
      ''
    end
  end

  module Hooks
    class ViewLayoutsBaseHook < Redmine::Hook::ViewListener
      render_on :view_layouts_base_html_head, :inline => "<%= stylesheet_link_tag :invoices, :plugin => 'redmine_contacts_invoices' %>"
    end
  end

end

class String
    def to_class
        Kernel.const_get self
    rescue NameError
        nil
    end

    def is_a_defined_class?
        true if self.to_class
    rescue NameError
        false
    end
end

