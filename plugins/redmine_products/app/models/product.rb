# This file is a part of Redmine Products (redmine_products) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2014 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_products is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_products is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_products.  If not, see <http://www.gnu.org/licenses/>.

class Product < ActiveRecord::Base
  unloadable
  include Redmine::SafeAttributes
  include ContactsMoneyHelper

  belongs_to :project
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  has_one :image, :class_name => "Attachment", :as  => :container, :conditions => "#{Attachment.table_name}.description = 'default_image'", :dependent => :destroy
  has_many :product_lines
  has_many :orders, :through => :product_lines, :source_type => "Order", :source => :container, :uniq => true
  has_many :contacts, :through => :orders, :uniq => true

  scope :by_project, lambda {|project_id| where(:project_id => project_id) unless project_id.blank? }
  scope :visible, lambda {|*args| { :include => :project,
                                          :conditions => Project.allowed_to_condition(args.first || User.current, :view_products)} }
  scope :live_search, lambda {|search| where("(LOWER(#{Product.table_name}.name) LIKE LOWER(:p))
                                             OR (LOWER(#{Product.table_name}.code) LIKE LOWER(:p))
                                             OR (LOWER(#{Product.table_name}.description) LIKE LOWER(:p))",
                                             {:p => "%#{search.downcase}%"}) }

  acts_as_event :datetime => :created_at,
                :url => Proc.new {|o| {:controller => 'products', :action => 'show', :id => o}},
                :type => 'icon-product',
                :title => Proc.new {|o| "#{l(:label_products_product_created)} #{o.name} - #{o.price.to_s}" },
                :description => Proc.new {|o| [o.description.to_s,  o.price.to_s].join(' ') }

  acts_as_activity_provider :type => 'products',
                            :permission => :view_products,
                            :timestamp => "#{table_name}.created_at",
                            :author_key => :author_id,
                            :find_options => {:include => :project}

  acts_as_searchable :columns => ["#{table_name}.name", "#{table_name}.description"],
                     :date_column => "#{table_name}.created_at",
                     :include => [:project],
                     :project_key => "#{Project.table_name}.id",
                     :permission => :view_products,
                     # sort by id so that limited eager loading doesn't break with postgresql
                     :order_column => "#{table_name}.name"

  acts_as_customizable
  acts_as_attachable
  acts_as_taggable

  ACTIVE_PRODUCT = 1
  INACTIVE_PRODUCT = 2

  validates_presence_of :name, :code, :status_id
  validates_uniqueness_of :code
  validates_numericality_of :price, :allow_nil => true
  validates_inclusion_of :status_id, :in => [ACTIVE_PRODUCT, INACTIVE_PRODUCT]

  safe_attributes 'code',
    'name',
    'status_id',
    'currency',
    'price',
    'amount',
    'description',
    'custom_field_values',
    'custom_fields',
    'tag_list',
    :if => lambda {|product, user| product.new_record? || user.allowed_to?(:edit_products, product.project) }

  def initialize(attributes=nil, *args)
    super
    if new_record?
      # set default values for new records only
      self.status_id ||= INACTIVE_PRODUCT
      self.currency ||= ContactsSetting.default_currency
    end
  end

  def visible?(usr=nil)
    (usr || User.current).allowed_to?(:view_products, self.project)
  end

  def editable_by?(usr, prj=nil)
    prj ||= @project || self.project
    usr && (usr.allowed_to?(:edit_products, prj))
  end

  def destroyable_by?(usr, prj=nil)
    prj ||= @project || self.project
    usr && (usr.allowed_to?(:delete_products, prj))
  end

  def status
    case self.status_id
    when ACTIVE_PRODUCT
      l(:label_products_status_active)
    when INACTIVE_PRODUCT
      l(:label_products_status_inactive)
    else
      ""
    end
  end

  def is_active?
    status_id == ACTIVE_PRODUCT
  end

  def is_inactive?
    status_id == INACTIVE_PRODUCT
  end

  def price_to_s
    object_price(self)
  end

  def to_s
    self.name
  end

  def self.available_tags(options = {})
    limit = options[:limit]

    scope = ActsAsTaggableOn::Tag.scoped({})
    scope = scope.scoped(:conditions => ["#{Project.table_name}.id = ?", options[:project]]) if options[:project]
    scope = scope.scoped(:conditions => [Project.allowed_to_condition(options[:user] || User.current, :view_products)])
    scope = scope.scoped(:conditions => ["LOWER(#{ActsAsTaggableOn::Tag.table_name}.name) LIKE ?", "%#{options[:name_like].downcase}%"]) if options[:name_like]

    joins = []
    joins << "JOIN #{ActsAsTaggableOn::Tagging.table_name} ON #{ActsAsTaggableOn::Tagging.table_name}.tag_id = #{ActsAsTaggableOn::Tag.table_name}.id "
    joins << "JOIN #{Product.table_name} ON #{Product.table_name}.id = #{ActsAsTaggableOn::Tagging.table_name}.taggable_id AND #{ActsAsTaggableOn::Tagging.table_name}.taggable_type = '#{Product.name}' "
    joins << "JOIN #{Project.table_name} ON #{Project.table_name}.id = #{Product.table_name}.project_id"

    options = {}
    options[:select] = "#{ActsAsTaggableOn::Tag.table_name}.*, COUNT(DISTINCT #{ActsAsTaggableOn::Tagging.table_name}.taggable_id) AS count"
    options[:joins] = joins.flatten
    options[:group] = "#{ActsAsTaggableOn::Tag.table_name}.id, #{ActsAsTaggableOn::Tag.table_name}.name HAVING COUNT(*) > 0"
    options[:order] = "#{ActsAsTaggableOn::Tag.table_name}.name"
    options[:limit] = limit if limit

    scope.find(:all, options)

  end

end
