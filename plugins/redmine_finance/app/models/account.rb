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

class Account < ActiveRecord::Base
  unloadable

  include ContactsMoneyHelper

  before_destroy :check_integrity

  belongs_to :project
  has_many :operations, :dependent => :destroy
  belongs_to :assigned_to, :class_name => 'Principal', :foreign_key => 'assigned_to_id'

  scope :visible, lambda {|*args| { :include => :project,
                                    :conditions => Project.allowed_to_condition(args.first || User.current, :view_finances)} }
  scope :named, lambda {|arg| where("LOWER(#{table_name}.name) = LOWER(?)", arg.to_s.strip)}

  acts_as_customizable
  acts_as_watchable
  acts_as_attachable :view_permission => :view_finances

  before_save :calculate_amount

  validates_presence_of :project, :currency
  validates_uniqueness_of :name

  def calculate_amount
    @account_amount_was = self.amount
    self.amount = self.operations.income.sum(:amount) - self.operations.outcome.sum(:amount)
  end

  def debit
    @debit ||= self.operations.income.sum(:amount)
  end

  def credit
    @credit ||= self.operations.outcome.sum(:amount)
  end

  def visible?(usr=nil)
    (usr || User.current).allowed_to?(:view_finances, self.project)
  end

  def editable_by?(usr=nil)
    (usr || User.current).allowed_to?(:edit_accounts, self.project)
  end

  def destroyable_by?(usr=nil)
    (usr || User.current).allowed_to?(:delete_accounts, self.project)
  end

  def balance(balance_date)
    self.operations.income.order("#{Operation.table_name}.operation_date DESC").select{|o| o.operation_date <= balance_date}.sum(&:amount) - self.operations.outcome.order("#{Operation.table_name}.operation_date DESC").select{|o| o.operation_date < balance_date}.sum(&:amount)
  end

  def recipients
    notified = []
    # Author and assignee are always notified unless they have been
    # locked or don't want to be notified
    # notified << author if author
    if assigned_to
      notified += (assigned_to.is_a?(Group) ? assigned_to.users : [assigned_to])
    end
    notified = notified.select {|u| u.active? && u.notify_about?(self)}

    notified += project.notified_users
    notified.uniq!
    # Remove users that can not view the contact
    notified.reject! {|user| !visible?(user)}
    notified.collect(&:mail)
  end

  def amount_to_s
    object_price(self, :amount)
  end

  def debit_to_s
    object_price(self, :debit)
  end

  def credit_to_s
    object_price(self, :credit)
  end

  def created_on
    created_at
  end

  def account_amount_was
    @account_amount_was
    # if amount_changed? && amount_was.present?
    #   @account_amount_was ||= amount_was
    # end
  end

  private

  def check_integrity
    raise Exception.new("Can't delete account") if Operation.where(:account_id => self.id).any?
  end

  def helpers
    ActionController::Base.helpers
  end

end
