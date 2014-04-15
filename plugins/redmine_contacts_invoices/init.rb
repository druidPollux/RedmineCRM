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

require 'redmine'

INVOICES_VERSION_NUMBER = '3.1.3'
INVOICES_VERSION_STATUS = ''

Redmine::Plugin.register :redmine_contacts_invoices do
  name 'Redmine Invoices plugin'
  author 'RedmineCRM'
  description 'Plugin for track invoices'
  version INVOICES_VERSION_NUMBER + '-light' + INVOICES_VERSION_STATUS
  url 'http://redminecrm.com/projects/invoices'
  author_url 'mailto:support@redminecrm.com'

  requires_redmine :version_or_higher => '2.1.2'
  requires_redmine_plugin :redmine_contacts, :version_or_higher => '3.2.14'

  settings :default => {
    :invoices_company_name => "Your company name",
    :invoices_company_representative => "Company representative name",
    :invoices_template  => "classic",
    :invoices_line_grouping => 0,
    :invoices_cross_project_contacts => true,
    :invoices_number_format => '#INV/%%YEAR%%%%MONTH%%%%DAY%%-%%ID%%',
    :invoices_company_info => "Your company address\nTax ID\nphone:\nfax:",
    :invoices_company_logo_url => "http://www.redmine.org/attachments/3458/redmine_logo_v1.png",
    :invoices_bill_info => "Your billing information (Bank, Address, IBAN, SWIFT & etc.)",
    :invoices_units  => "hours\ndays\nservice\nproducts"
  }, :partial => 'settings/invoices/invoices'


  project_module :contacts_invoices do
    permission :view_invoices, :invoices => [:index, :show, :context_menu],
                               :recurring_invoices => [:index, :show, :context_menu]
    permission :add_invoices, :invoices => [:new, :create]
    permission :edit_invoices, :invoices => [:new, :create, :edit, :update, :bulk_update],
                               :invoice_time_entries => [:new]
    permission :edit_own_invoices, :invoices => [:new, :create, :edit, :update, :delete]
    permission :delete_invoices, :invoices => [:destroy, :bulk_destroy]
    permission :comment_invoices,  :invoice_comments => :create
    permission :edit_invoice_payments,  :invoice_payments => [:new, :create, :destroy]
  end

  menu :top_menu, :invoices, {:controller => 'invoices', :action => 'index', :project_id => nil}, :caption => :label_invoice_plural, :if => Proc.new {
    User.current.allowed_to?({:controller => 'invoices', :action => 'index'}, nil, {:global => true}) && RedmineInvoices.settings[:invoices_show_invoices_in_top_menu]
  }

  menu :application_menu, :invoices,
                          {:controller => 'invoices', :action => 'index'},
                          :caption => :label_invoice_plural,
                          :param => :project_id,
                          :if => Proc.new{User.current.allowed_to?({:controller => 'invoices', :action => 'index'},
                                          nil, {:global => true}) && RedmineInvoices.settings[:invoices_show_in_app_menu]}

  menu :project_menu, :invoices, {:controller => 'invoices', :action => 'index'}, :caption => :label_invoice_plural, :param => :project_id

  menu :admin_menu, :invoices, {:controller => 'settings', :action => 'plugin', :id => "redmine_contacts_invoices"}, :caption => :label_invoice_plural, :param => :project_id

  activity_provider :invoices, :default => false, :class_name => ['InvoicePayment', 'Invoice']

  Redmine::Search.map do |search|
    search.register :invoices
  end

end

require 'redmine_invoices'
