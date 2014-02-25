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

class Invoice < ActiveRecord::Base
  unloadable
  include ContactsMoneyHelper

  ESTIMATE_INVOICE = 0
  DRAFT_INVOICE = 1
  SENT_INVOICE = 2
  PAID_INVOICE = 3
  CANCELED_INVOICE = 4

  belongs_to :contact
  belongs_to :project
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  belongs_to :assigned_to, :class_name => "User", :foreign_key => "assigned_to_id"
  has_many :lines, :class_name => "InvoiceLine", :foreign_key => "invoice_id", :order => "position", :dependent => :delete_all
  has_many :comments, :as => :commented, :dependent => :delete_all, :order => "created_on"
  has_many :payments, :class_name => "InvoicePayment", :dependent => :delete_all, :order => "payment_date"

  scope :by_project, lambda {|project_id| where(["#{Invoice.table_name}.project_id = ?", project_id]) unless project_id.blank? }


  scope :visible, lambda {|*args| { :include => :project,
                                          :conditions => Project.allowed_to_condition(args.first || User.current, :view_invoices)} }
  scope :live_search, lambda {|search| {:conditions =>   ["(LOWER(#{Invoice.table_name}.number) LIKE ? OR
                                                                  LOWER(#{Invoice.table_name}.subject) LIKE ? OR
                                                                  LOWER(#{Invoice.table_name}.description) LIKE ?)",
                                                                 "%" + search.downcase + "%",
                                                                 "%" + search.downcase + "%",
                                                                 "%" + search.downcase + "%"] }}
  scope :paid, where(:status_id => PAID_INVOICE)
  scope :sent_or_paid, where(["#{Invoice.table_name}.status_id = ? OR #{Invoice.table_name}.status_id = ?", PAID_INVOICE, SENT_INVOICE])
  scope :open, where(["#{Invoice.table_name}.status_id <> ? AND #{Invoice.table_name}.status_id <> ?", PAID_INVOICE, CANCELED_INVOICE])

  acts_as_event :datetime => :created_at,
                :url => Proc.new {|o| {:controller => 'invoices', :action => 'show', :id => o}},
                :type => 'icon-invoice',
                :title => Proc.new {|o| "#{l(:label_invoice_created)} ##{o.number} (#{o.status}): #{o.currency + ' ' if o.currency}#{o.amount}" },
                :description => Proc.new {|o| [o.number, o.contact ? o.contact.name : '', o.currency.to_s + " " + o.amount.to_s, o.description].join(' ') }

  acts_as_activity_provider :type => 'invoices',
                            :permission => :view_invoices,
                            :timestamp => "#{table_name}.created_at",
                            :author_key => :author_id,
                            :find_options => {:include => :project}

  acts_as_searchable :columns => ["#{table_name}.number"],
                     :date_column => "#{table_name}.created_at",
                     :include => [:project],
                     :project_key => "#{Project.table_name}.id",
                     :permission => :view_invoices,
                     # sort by id so that limited eager loading doesn't break with postgresql
                     :order_column => "#{table_name}.number"

  acts_as_customizable
  acts_as_watchable
  acts_as_attachable

  before_save :calculate_amount

  validates_presence_of :number, :invoice_date, :project, :status_id
  validates_uniqueness_of :number
  validates_numericality_of :discount, :allow_nil => true
  validate :validate_invoice

  accepts_nested_attributes_for :lines, :allow_destroy => true

  def calculate_status
    self.calculate_balance
    if self.balance >= self.amount
      self.status_id = Invoice::PAID_INVOICE
      self.paid_date = self.payments.maximum(:payment_date)
    else
      self.status_id = Invoice::SENT_INVOICE
      self.paid_date = nil
    end
  end

  def calculate_balance
    payments_sum = self.payments.sum(&:amount)
    self.balance = payments_sum > self.amount ? self.amount : payments_sum
  end

  def calculate_amount
    self.amount = self.subtotal + (ContactsSetting.tax_exclusive? ? self.tax_amount : 0) - discount_amount
  end
  alias_method :calculate, :calculate_amount


  def tax_amount
    self.lines.inject(0){|sum,x| sum + x.tax_amount}.to_f
  end

  def subtotal
    self.lines.inject(0){|sum,x| sum + x.total}.to_f
  end

  def discount_amount
    ((discount_rate.to_f/100) * ((InvoicesSettings[:invoices_discount_after_tax, self.project].to_i > 0) ? subtotal + tax_amount : subtotal))
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

  def tax_groups
    self.lines.select{|l| !l.tax.blank? && l.tax.to_f > 0}.group_by{|l| l.tax}.map{|k, v| [k, v.sum{|l| l.tax_amount.to_f}] }
  end

  def visible?(usr=nil)
    (usr || User.current).allowed_to?(:view_invoices, self.project)
  end

  def editable_by?(usr, prj=nil)
    prj ||= @project || self.project
    usr && (usr.allowed_to?(:edit_invoices, prj) || (self.author == usr && usr.allowed_to?(:edit_own_invoices, prj)))
    # usr && usr.logged? && (usr.allowed_to?(:edit_notes, project) || (self.author == usr && usr.allowed_to?(:edit_own_notes, project)))
  end

  def destroyable_by?(usr, prj=nil)
    prj ||= @project || self.project
    usr && (usr.allowed_to?(:delete_invoices, prj) || (self.author == usr && usr.allowed_to?(:edit_own_invoices, prj)))
  end

  def commentable?(user=User.current)
    user.allowed_to?(:comment_invoices, project)
  end

  def total_with_tax?
    @total_with_tax ||= !InvoicesSettings.disable_taxes?(self.project) && (InvoicesSettings[:invoices_total_including_tax, self.project].to_i > 0)
  end

  def copy_from(arg)
    invoice = arg.is_a?(Invoice) ? arg : Invoice.visible.find(arg)
    self.attributes = invoice.attributes.dup.except("id", "number", "created_at", "updated_at")
    self.lines = invoice.lines.collect{|l| InvoiceLine.new(l.attributes.dup.except("id", "created_at", "updated_at"))}
    self.custom_field_values = invoice.custom_field_values.inject({}) {|h,v| h[v.custom_field_id] = v.value; h}
    self
  end

  def self.allowed_target_projects(user=User.current)
    Project.all(:conditions => Project.allowed_to_condition(user, :edit_invoices))
  end

  STATUSES = {
    DRAFT_INVOICE => :label_invoice_status_draft,
    ESTIMATE_INVOICE => :label_invoice_status_estimate,
    SENT_INVOICE => :label_invoice_status_sent,
    PAID_INVOICE => :label_invoice_status_paid,
    CANCELED_INVOICE => :label_invoice_status_canceled
  }

  def status
    l(STATUSES[status_id])
  end

  def set_status(st)
    STATUSES.respond_to?(:key) ? STATUSES.key(st) : STATUSES.index(st)
  end

  def is_draft
    status_id == DRAFT_INVOICE || status_id.blank?
  end

  def is_sent?
    status_id == SENT_INVOICE
  end

  def is_paid?
    status_id == PAID_INVOICE
  end

  def is_canceled?
     status_id == CANCELED_INVOICE
  end

  def is_estimate?
     status_id == ESTIMATE_INVOICE
  end

  def is_open?
    ![PAID_INVOICE, CANCELED_INVOICE].include?(status_id)
  end

  def editable?(usr=nil)
    @editable ||= editable_by?(usr)
  end

  def amount_to_s
    object_price(self, :amount)
  end

  def remaining_balance
    self.amount - self.balance
  end

  def has_taxes?
    !self.lines.map(&:tax).all?{|t| t == 0 || t.blank?}
  end

  def has_units?
    !self.lines.map(&:units).all?{|t| t == 0 || t.blank?}
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

  def filename
    "invoice-#{self.number.to_s}.pdf"
  end

  def self.sum_by_period(peroid, project, contact_id=nil)
    from, to = RedmineContacts::DateUtils.retrieve_date_range(peroid)
    scope = Invoice.scoped({})
    scope = scope.visible
    scope = scope.by_project(project.id) if project
    scope = scope.where("#{Invoice.table_name}.invoice_date >= ? AND #{Invoice.table_name}.invoice_date < ?", from, to)
    scope = scope.where("#{Invoice.table_name}.contact_id = ?", contact_id) unless contact_id.blank?
    scope = scope.sent_or_paid
    scope.sum(:amount, :group => :currency)
  end

  def self.sum_by_status(status_id, project, contact_id=nil)
    scope = Invoice.scoped({})
    scope = scope.visible
    scope = scope.by_project(project.id) if project
    scope = scope.where("#{Invoice.table_name}.status_id = ?", status_id)
    scope = scope.where("#{Invoice.table_name}.contact_id = ?", contact_id) unless contact_id.blank?
    [scope.sum(:amount, :group => :currency), scope.count(:number)]
  end

  private

  def validate_invoice
    if (status_id != PAID_INVOICE && remaining_balance == 0 && balance > 0) || (status_id == PAID_INVOICE && remaining_balance > 0 && amount > 0)
      errors.add :status_id, :text_invoice_cant_change_status
    end
  end


end
