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

class InvoicePayment < ActiveRecord::Base
  unloadable
  include ContactsMoneyHelper

  belongs_to :invoice
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"

  delegate :currency, :to => :invoice, :allow_nil => true

  after_create :save_invoice_balance
  after_destroy :save_invoice_balance

  acts_as_event :datetime => :created_at,
                :url => Proc.new {|o| {:controller => 'invoices', :action => 'show', :id => o.invoice_id}},
                :group => :invoice,
                :type => 'icon-add-payment',
                :title => Proc.new {|o| "#{l(:label_invoice_payment_created)} #{format_date(o.payment_date)} - #{o.amount.to_s}" },
                :description => Proc.new {|o| [format_date(o.payment_date), o.description.to_s, o.invoice.blank? ? "" : o.invoice.number].join(' ') }

  acts_as_activity_provider :type => 'invoices',
                            :permission => :view_invoices,
                            :timestamp => "#{table_name}.created_at",
                            :author_key => :author_id,
                            :find_options => {:include => {:invoice => :project}}

  acts_as_customizable
  acts_as_attachable :view_permission => :view_invoices,
                     :delete_permission => :edit_invoice_payments

  validates_presence_of :invoice, :amount, :payment_date

  def project
    self.invoice.project
  end

  def amount_to_s
    object_price(self, :amount)
  end

  private

  def save_invoice_balance
    self.invoice.calculate_status
    self.invoice.save
  end

  # def check_invoice_status
  #   self.invoice.balance = [self.invoice.payments.sum(&:amount) - self.amount, self.invoice.amount].min
  #   if self.invoice.payments.sum(&:amount) - self.amount <= self.invoice.amount
  #     self.invoice.status_id = Invoice::SENT_INVOICE
  #     self.invoice.paid_date = nil
  #   else
  #     self.invoice.payments.delete(self)
  #     self.invoice.paid_date = self.invoice.payments.maximum(:payment_date)
  #   end
  #   self.invoice.save
  # end

end
