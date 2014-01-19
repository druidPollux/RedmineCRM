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

resources :invoices do
  member do
    get :client_view
  end
 	collection do
    get :auto_complete
 		get :bulk_edit, :context_menu
 		post :bulk_edit, :bulk_update
 		delete :bulk_destroy
 	end
end

resources :recurring_invoices do
end

resources :invoices do
  resources :invoice_payments, :as => :payments
end
resources :invoice_comments, :only => [:create, :destroy]

resources :projects do
	resources :invoices, :only => [:index, :new, :create]
end

match "invoices_time_entries/:action", :controller => "invoices_time_entries"

