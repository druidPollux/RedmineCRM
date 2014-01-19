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

class LedgerItem < ActiveRecord::Base
  unloadable
  include ContactsMoneyHelper

  self.table_name = "#{table_name_prefix}invoices#{table_name_suffix}"

  belongs_to :contact
  belongs_to :project
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  belongs_to :assigned_to, :class_name => "User", :foreign_key => "assigned_to_id"
  has_many :lines, :class_name => "InvoiceLine", :foreign_key => "invoice_id", :order => "position", :dependent => :delete_all
  has_many :comments, :as => :commented, :dependent => :delete_all, :order => "created_on"
  scope :by_project, lambda {|project_id| where(["#{table_name}.project_id = ?", project_id]) unless project_id.blank? }
  scope :live_search, lambda {|search| {:conditions =>   ["(LOWER(#{table_name}.number) LIKE ? OR
                                                           LOWER(#{table_name}.subject) LIKE ? OR
                                                           LOWER(#{table_name}.description) LIKE ?)",
                                                           "%" + search.downcase + "%",
                                                           "%" + search.downcase + "%",
                                                           "%" + search.downcase + "%"] }}
  acts_as_watchable
  acts_as_attachable

  before_save :calculate_amount

  validates_presence_of :number, :invoice_date, :project, :status_id
  validates_uniqueness_of :number, :scope => :type

  accepts_nested_attributes_for :lines, :allow_destroy => true

  def calculate_amount
     self.amount = self.subtotal + (ContactsSetting.tax_exclusive? ? self.tax_amount : 0)
  end

  def subtotal
    self.lines.inject(0){|sum,x| sum + x.tax_amount}
  end

  def tax_amount
    self.lines.inject(0){|sum,x| sum + x.tax_amount}
  end

  def discount_rate
    case discount_type
    when 0
      (discount % 100)
    when 1
      subtotal != 0 ? ((100 / ((InvoicesSettings[:invoices_discount_after_tax, self.project].to_i > 0) ? subtotal + tax_amount : subtotal)) * discount) : 0
    else
      (discount % 100)
    end
  end

  def discount_amount
    ((discount_rate.to_f/100) * ((InvoicesSettings[:invoices_discount_after_tax, self.project].to_i > 0) ? subtotal + tax_amount : subtotal))
  end

  def total_with_tax?
    @total_with_tax ||= !InvoicesSettings.disable_taxes?(self.project) && (InvoicesSettings[:invoices_total_including_tax, self.project].to_i > 0)
  end

  def tax_groups
    self.lines.select{|l| !l.tax.blank? && l.tax.to_f > 0}.group_by{|l| l.tax}.map{|k, v| [k, v.sum{|l| l.tax_amount.to_f}] }
  end

  def amount_to_s; price_to_currency(amount, currency); end
  def subtotal_to_s; price_to_currency(subtotal, currency); end
  def tax_amount_to_s; price_to_currency(tax_amount, currency); end

  def has_taxes?
    !self.lines.map(&:tax).all?{|t| t == 0 || t.blank?}
  end

  def has_units?
    !self.lines.map(&:units).all?(&:blank?)
  end

  def copy_from(arg)
    invoice = arg.is_a?(LedgerItem) ? arg : LedgerItem.find(arg)
    self.attributes = invoice.attributes.dup.except("id", "number", "created_at", "updated_at")
    self.lines = invoice.lines.collect{|l| InvoiceLine.new(l.attributes.dup.except("id", "created_at", "updated_at", "invoice_id"))}
    self
  end

  protected

  def helpers
    ActionController::Base.helpers
  end

end
