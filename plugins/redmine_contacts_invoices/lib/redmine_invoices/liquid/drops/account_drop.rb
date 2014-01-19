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

class AccountDrop < Liquid::Drop

  def initialize(project)
    @project = project
  end

  def bill_info
    InvoicesSettings[:invoices_bill_info, @project]
  end

  def company
    InvoicesSettings[:invoices_company_name, @project]
  end

  def representative
    InvoicesSettings[:invoices_company_representative, @project]
  end

  def info
    InvoicesSettings[:invoices_company_info, @project]
  end

  def logo
    InvoicesSettings[:invoices_company_logo_url, @project]
  end

  private

  def helpers
    Rails.application.routes.url_helpers
  end

end
