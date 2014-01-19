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

class RecurringInvoice < LedgerItem
  unloadable

  INACTIVE_RECURRING = 0
  ACTIVE_RECURRING = 1

  STATUSES = {
    INACTIVE_RECURRING => l(:label_invoice_inactive_recurring),
    ACTIVE_RECURRING => l(:label_invoice_active_recurring)
  }

  PERIODS = {
    :weekly => 7.days,
    :every2weeks => 14.days,
    :every4weeks => 28.days,
    :monthly => 1.month,
    :every2months => 2.months,
    :quarterly => 3.months,
    :twiceayear => 6.months,
    :yearly => 1.year,
    :every2years => 2.years
  }

  @@sorted_keys ||= PERIODS.keys.sort{ |a,b| PERIODS[a] <=> PERIODS[b]}
  @@sorted_keys.each_with_index do |key, i|
    self.const_set(key.to_s.upcase, i)
  end

  belongs_to :contact
  belongs_to :project
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  belongs_to :assigned_to, :class_name => "User", :foreign_key => "assigned_to_id"
  has_many :lines, :class_name => "InvoiceLine", :foreign_key => "invoice_id", :order => "position", :dependent => :delete_all

  scope :visible, lambda {|*args| { :include => :project,
                                          :conditions => Project.allowed_to_condition(args.first || User.current, :view_invoices)} }
  scope :active, where(:status_id => ACTIVE_RECURRING)

  def visible?(usr=nil)
    (usr || User.current).allowed_to?(:view_invoices, self.project)
  end


  def self.allowed_target_projects(user=User.current)
    Project.all(:conditions => Project.allowed_to_condition(user, :edit_invoices))
  end


  def status
    STATUSES[status_id]
  end

  def set_status(st)
    STATUSES.respond_to?(:key) ? STATUSES.key(st) : STATUSES.index(st)
  end

  def is_active?
    status_id == ACTIVE_RECURRING
  end

  def generate_invoice
    return false unless self.is_active?

    new_invoice = Invoice.new.copy_from(self)
    new_invoice.number = Invoice.generate_invoice_number(self.project)
    new_invoice.number = Invoice.order(:id).last.id.to_i + 1 if new_invoice.number.blank? || Invoice.where(:number => new_invoice.number).count > 0
    new_invoice.invoice_date = Date.today
    new_invoice.save!
  end

  def self.generate_invoice_number(project=nil)
    result = ""
    format = InvoicesSettings[:invoices_invoice_number_format, project].to_s
    if format
      result = format.gsub(/%%ID%%/, "%02d" % (Invoice.last.try(:id).to_i + 1).to_s)
      result = result.gsub(/%%YEAR%%/, Date.today.year.to_s)
      result = result.gsub(/%%MONTH%%/, "%02d" % Date.today.month.to_s)
      result = result.gsub(/%%DAY%%/, "%02d" % Date.today.day.to_s)
      result = result.gsub(/%%DAILY_ID%%/, "%02d" % (Invoice.count(:conditions => {:invoice_date => Time.now.to_time.utc.change(:hour => 0, :min => 0)}) + 1).to_s)
      result = result.gsub(/%%MONTHLY_ID%%/, "%03d" % (Invoice.count(:conditions => {:invoice_date => Time.now.beginning_of_month.utc.change(:hour => 0, :min => 0).. Time.now.end_of_month.utc.change(:hour => 0, :min => 0)}) + 1).to_s)
      result = result.gsub(/%%YEARLY_ID%%/, "%04d" % (Invoice.count(:conditions => {:invoice_date => Time.now.beginning_of_year.utc.change(:hour => 0, :min => 0).. Time.now.end_of_year.utc.change(:hour => 0, :min => 0)}) + 1).to_s)
      result = result.gsub(/%%MONTHLY_PROJECT_ID%%/, "%03d" % (Invoice.count(:conditions => {:project_id => project, :invoice_date => Time.now.beginning_of_month.utc.change(:hour => 0, :min => 0).. Time.now.end_of_month.utc.change(:hour => 0, :min => 0)}) + 1).to_s)
      result = result.gsub(/%%YEARLY_PROJECT_ID%%/, "%04d" % (Invoice.count(:conditions => {:project_id => project, :invoice_date => Time.now.beginning_of_year.utc.change(:hour => 0, :min => 0).. Time.now.end_of_year.utc.change(:hour => 0, :min => 0)}) + 1).to_s)
    end

  end

end
