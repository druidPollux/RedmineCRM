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

# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :accounts
resources :operations do
  collection do
      get :bulk_edit, :context_menu, :auto_complete
      delete :bulk_destroy
  end
end
resources :operation_categories
resources :operation_comments, :only => [:create, :destroy]
resources :operation_invoices, :only => [:create, :destroy]
resources :operation_relations, :only => [:create, :destroy]

resources :operation_imports, :only => [:new, :create]

resources :projects do
  resources :operations
end

resources :projects do
  resources :accounts
end
