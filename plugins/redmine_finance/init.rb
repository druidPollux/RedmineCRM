# This file is a part of Redmine Finance (redmine_finance) plugin,
# simple accounting plugin for Redmine
#
# Copyright (C) 2011-2013 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_finance is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_finance is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_finance.  If not, see <http://www.gnu.org/licenses/>.

ActiveRecord::Base.observers += [:operation_observer]

FINANCE_VERSION_NUMBER = '1.0.9'
FINANCE_VERSION_STATUS = ''

Redmine::Plugin.register :redmine_finance do
  name 'Redmine Finance plugin'
  author 'RedmineCRM'
  description 'This is a accounting plugin for Redmine'
  version FINANCE_VERSION_NUMBER + '-light' + FINANCE_VERSION_STATUS
  url 'http://redminecrm.com/projects/finance'
  author_url 'mailto:support@redminecrm.com'

  requires_redmine :version_or_higher => '2.1.2'
  requires_redmine_plugin :redmine_contacts, :version_or_higher => '3.2.14'

  settings :default => {
    :finance_default_currency => "USD",
    :finance_decimal_separator => ".",
    :finance_thousands_delimiter => " "
  }, :partial => 'settings/finance'

  project_module :finance do
    permission :view_finances, :operations => [:index, :show, :context_menu], :accounts => [:index, :show, :context_menu]

    permission :edit_operations, :operations => [:new, :create, :edit, :update, :bulk_update]
    permission :edit_own_operations, :operations => [:new, :create, :edit, :update, :delete]
    permission :delete_operations, :operations => [:destroy, :bulk_destroy]
    permission :comment_operations, {:operation_comments => :create}
    permission :delete_operation_comments, {:operation_comments => :destroy}
    permission :edit_accounts, :accounts => [:new, :create, :edit, :update, :bulk_update]
    permission :delete_accounts, :accounts => [:destroy, :bulk_destroy]

  end

  menu :admin_menu, :finance, {:controller => 'settings', :action => 'plugin', :id => "redmine_finance"}, :caption => :label_finance
  menu :top_menu, :finance, {:controller => 'operations', :action => 'index', :project_id => nil}, :caption => :label_finance, :if => Proc.new {
    User.current.allowed_to?({:controller => 'operations', :action => 'index'}, nil, {:global => true}) && RedmineFinance.settings[:show_in_top_menu]
  }
  menu :application_menu, :finance,
                          {:controller => 'operations', :action => 'index'},
                          :caption => :label_finance_plural,
                          :param => :project_id,
                          :if => Proc.new{User.current.allowed_to?({:controller => 'operations', :action => 'index'},
                                          nil, {:global => true}) && RedmineFinance.settings[:show_in_app_menu]}

  menu :project_menu, :operations, {:controller => 'operations', :action => 'index'}, :caption => :label_finance_plural, :param => :project_id

  activity_provider :finances, :default => false, :class_name => ['Operation']

end

require 'redmine_finance'
