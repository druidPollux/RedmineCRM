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
  module WikiMacros
    Redmine::WikiFormatting::Macros.register do
      desc "Invoice"
      macro :invoice do |obj, args|
        args, options = extract_macro_options(args, :parent)
        raise 'No or bad arguments.' if args.size != 1
        invoice = Invoice.visible.find_by_number(args.first)
        return '' unless invoice
        s = ''
        s << "#{link_to(invoice.number, invoice_path(invoice))} #{invoice.subject}"
        s << ' - ' + invoice.amount_to_s if invoice.amount
        s.html_safe
      end
    end

  end
end
