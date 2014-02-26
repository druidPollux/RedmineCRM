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

class Operation < ActiveRecord::Base
  unloadable

  include ContactsMoneyHelper

  belongs_to :account
  belongs_to :contact
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  belongs_to :category, :class_name => "OperationCategory", :foreign_key => "category_id"
  delegate :project, :to => :account, :allow_nil => false
  delegate :currency, :to => :account, :allow_nil => true
  delegate :recipients, :watcher_recipients, :to => :account, :allow_nil => true
  has_many :comments, :as => :commented, :dependent => :delete_all, :order => "created_on"

  scope :visible, lambda {|*args| { :include => {:account => :project},
                                    :conditions => Project.allowed_to_condition(args.first || User.current, :view_finances)} }

  scope :income, includes(:category).where(:operation_categories => {:is_income => true})
  scope :outcome, includes(:category).where(:operation_categories => {:is_income => false})

  scope :live_search, lambda {|search| {:conditions =>   ["(#{Operation.table_name}.id = ? OR
                                                           LOWER(#{Operation.table_name}.description) LIKE ?)",
                                                           search.downcase,
                                                           "%" + search.downcase + "%"] }}

  acts_as_event :datetime => :created_at,
                :url => Proc.new {|o| {:controller => 'operations', :action => 'show', :id => o}},
                :type => Proc.new {|o| o.is_income? ? "icon-operation-income" : "icon-operation-outcome"},
                :title => Proc.new {|o| "#{o.category_name} ##{o.id}: #{'-' unless o.is_income? }#{o.amount_to_s}" },
                :description => Proc.new {|o| o.description.to_s }

  acts_as_activity_provider :type => 'finances',
                            :permission => :view_finances,
                            :timestamp => "#{table_name}.created_at",
                            :author_key => :author_id,
                            :find_options => {:include => {:account => :project}}

  after_save :save_account_amount
  after_destroy :save_account_amount

  validates_presence_of :account, :author, :operation_date, :category, :amount
  validates_numericality_of :amount, :greater_than => 0, :allow_nil => false

  def relations
    @relations ||= (relation_sources | relation_destinations).sort
  end

  def category_name
    self.category.name
  end

  def is_income?
    self.category.is_income?
  end

  def amount=(am)
    super am.to_s.gsub(/,/,'.')
  end

  def amount_to_s
    object_price(self, :amount)
  end

  def amount_with_sign
    s = ""
    s << "-" unless self.category.is_income?
    s << self.amount_to_s
  end

  def visible?(usr=nil)
    (usr || User.current).allowed_to?(:view_finances, self.project)
  end

  def editable_by?(usr, prj=nil)
    prj ||= @project || self.project
    usr && (usr.allowed_to?(:edit_operations, prj) || (self.author == usr && usr.allowed_to?(:edit_own_operations, prj)))
    # usr && usr.logged? && (usr.allowed_to?(:edit_notes, project) || (self.author == usr && usr.allowed_to?(:edit_own_notes, project)))
  end

  def destroyable_by?(usr, prj=nil)
    prj ||= @project || self.project
    usr && (usr.allowed_to?(:delete_operations, prj) || (self.author == usr && usr.allowed_to?(:edit_own_operations, prj)))
  end

  def commentable?(user=User.current)
    user.allowed_to?(:comment_operations, project)
  end

  def copy_from(arg)
    operation = arg.is_a?(Operation) ? arg : Operation.visible.find(arg)
    self.attributes = operation.attributes.dup.except("id", "operation_date", "created_at", "updated_at")
    self.custom_field_values = operation.custom_field_values.inject({}) {|h,v| h[v.custom_field_id] = v.value; h}
    self
  end

  def operation_date
    zone = User.current.time_zone
    zone ? super.in_time_zone(zone) : (super.utc? ? super.localtime : super)
  end

  def all_dependent_operations(except=[])
    except << self
    dependencies = []
    relation_sources.each do |relation|
      if relation.operation_destination && !except.include?(relation.operation_destination)
        dependencies << relation.operation_destination
        dependencies += relation.operation_destination.all_dependent_operations(except)
      end
    end
    dependencies
  end

  def created_on
    created_at
  end

  def to_s
    "#{self.category_name} ##{self.id}: #{'-' unless self.is_income? }#{self.amount_to_s}"
  end

  private


  def save_account_amount
    if self.account_id_changed?
      Account.find_by_id(self.account_id_was).try(:save)
    end
    # self.account.calculate_amount
    self.account.save
  end

  def save_account_amount_destroy
    # self.account.operations.delete(self)
    # self.account.calculate_amount
    self.account.save
  end

end
