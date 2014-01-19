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

module RedmineInvoices
  module Patches
    module ContactsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.send(:include, InvoicesHelper)

        base.class_eval do
          unloadable

          alias_method_chain :contact_tabs, :invoices          
        end
      end


      module InstanceMethods
        # include ContactsHelper

        def contact_tabs_with_invoices(contact)
          tabs = contact_tabs_without_invoices(contact)

          if contact.invoices.visible.count > 0
            tabs.push({:name => 'invoices', :partial => 'invoices/related_invoices', :label => l(:label_invoice_plural) + " (#{contact.invoices.visible.count})" } )
          end
          tabs
        end
        
      end
      
    end
  end
end

unless ContactsHelper.included_modules.include?(RedmineInvoices::Patches::ContactsHelperPatch)
  ContactsHelper.send(:include, RedmineInvoices::Patches::ContactsHelperPatch)
end
