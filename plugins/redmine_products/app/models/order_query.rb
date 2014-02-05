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

class OrderQuery < Query

  self.queried_class = Order

  self.available_columns = [
    QueryColumn.new(:order_number, :sortable => "#{Order.table_name}.number", :caption => :label_products_number),
    QueryColumn.new(:order_subject, :sortable => "#{Order.table_name}.subject", :caption => :label_products_order_subject),
    QueryColumn.new(:products, :caption => :label_product_plural),
    QueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => "#{Order.table_name}.project_id"),
    QueryColumn.new(:contact, :sortable => "#{Contact.table_name}.last_name", :groupable => true, :caption => :label_contact),
    QueryColumn.new(:contact_city, :caption => :label_products_contact_city, :groupable => "#{Address.table_name}.city", :sortable => "#{Address.table_name}.city"),
    QueryColumn.new(:contact_country, :caption => :label_products_contact_country, :groupable => "#{Address.table_name}.country_code", :sortable => "#{Address.table_name}.country_code"),
    QueryColumn.new(:order_date, :sortable => "#{Order.table_name}.order_date", :default_order => 'desc', :caption => :label_products_order_date),
    QueryColumn.new(:order_amount, :sortable => ["#{Order.table_name}.currency", "#{Order.table_name}.amount"], :default_order => 'desc', :caption => :label_products_amount),
    QueryColumn.new(:author, :sortable => lambda {User.fields_for_order_statement}, :groupable => "#{Order.table_name}.author_id"),
    QueryColumn.new(:assigned_to, :sortable => lambda {User.fields_for_order_statement}, :groupable => "#{Order.table_name}.assigned_to_id"),
    QueryColumn.new(:status, :sortable => "#{OrderStatus.table_name}.position", :groupable => "#{Order.table_name}.status_id", :caption => :label_products_status),
    QueryColumn.new(:created_at, :sortable => "#{Order.table_name}.created_at", :default_order => 'desc', :caption => :field_created_on),
    QueryColumn.new(:updated_at, :sortable => "#{Order.table_name}.updated_at", :default_order => 'desc', :caption => :field_updated_on),
  ]

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= { 'status_id' => {:operator => "o", :values => [""]} }
  end

  def initialize_available_filters
    add_available_filter "number", :type => :string, :label => :label_products_number
    add_available_filter "subject", :type => :text, :label => :label_products_order_subject
    add_available_filter "amount", :type => :float, :label => :label_products_amount
    add_available_filter "created_at", :type => :date_past, :label => :field_created_on
    add_available_filter "updated_at", :type => :date_past, :label => :field_updated_on
    add_available_filter "closed_date", :type => :date_past, :label => :label_products_closed_date
    add_available_filter "order_date", :type => :date, :label => :label_products_order_date

    principals = []
    if project && all_projects.any?
      principals += Principal.member_of(all_projects)
    end

    if project.nil?
      project_values = []
      if User.current.logged? && User.current.memberships.any?
        project_values << ["<< #{l(:label_my_projects).downcase} >>", "mine"]
      end
      project_values += all_projects_values
      add_available_filter("project_id",
        :type => :list, :values => project_values
      ) unless project_values.empty?
    end

    principals.uniq!
    principals.sort!
    users = principals.select {|p| p.is_a?(User)}

    users_values = []
    users_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    users_values += users.collect{|s| [s.name, s.id.to_s] }
    add_available_filter("author_id",
      :type => :list_optional, :values => users_values
    ) unless users_values.empty?

    order_statuses = OrderStatus.all
    add_available_filter("status_id",
      :type => :list_status, :values => order_statuses.map {|a| [a.name, a.id.to_s]}, :label => :label_products_status
    ) unless order_statuses.empty?

    products = Product.visible.all
    add_available_filter("products",
      :type => :list_optional, :values => products.map {|a| [a.name, a.id.to_s]}, :label => :label_product_plural
    ) unless products.empty?

    contact_countries = l(:label_crm_countries).map{|k, v| [v, k]}
    add_available_filter("contact_country",
      :type => :list_optional, :values => contact_countries, :label => :label_products_contact_country
    ) unless contact_countries.empty?

    add_available_filter "contact_city", :type => :string, :label => :label_products_contact_city
    add_associations_custom_fields_filters :project, :contact, :products, :lines
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup
    @available_columns += CustomField.where(:type => 'OrderCustomField').all.map {|cf| QueryCustomFieldColumn.new(cf) }
    @available_columns += CustomField.where(:type => 'ContactCustomField').all.map {|cf| QueryAssociationCustomFieldColumn.new(:contact, cf) }
    @available_columns
  end

  def default_columns_names
    @default_columns_names ||= [:order_number, :order_date, :order_amount, :contact]
  end

  def sql_for_contact_country_field(field, operator, value)
    if operator == '*' # Any group
      contact_countries = l(:label_crm_countries).map{|k, v| k.to_s}
      operator = '=' # Override the operator since we want to find by assigned_to
    elsif operator == "!*"
      contact_countries = l(:label_crm_countries).map{|k, v| k.to_s}
      operator = '!' # Override the operator since we want to find by assigned_to
    else
      contact_countries = value
    end
    '(' + sql_for_field("address_id", operator, contact_countries, Address.table_name, "country_code", false) + ')'
  end

  def sql_for_contact_city_field(field, operator, value)
     sql_for_field(field, operator, value, Address.table_name, "city")
  end

  def sql_for_order_subject_field(field, operator, value)
     sql_for_field(field, operator, value, Order.table_name, "subject")
  end

  def sql_for_order_number_field(field, operator, value)
     sql_for_field(field, operator, value, Order.table_name, "number")
  end

  def sql_for_order_amount_field(field, operator, value)
     sql_for_field(field, operator, value, Order.table_name, "amount")
  end

  def sql_for_products_field(field, operator, value)
    if operator == '*' # Any group
      products = Product.visible.all
      operator = '=' # Override the operator since we want to find by assigned_to
    elsif operator == "!*"
      products = Product.visible.all
      operator = '!' # Override the operator since we want to find by assigned_to
    else
      products = Product.visible.find_all_by_id(value)
    end
    products ||= []

    order_products = products.map(&:id).uniq.compact.sort.collect(&:to_s)

    '(' + sql_for_field("product_id", operator, order_products, ProductLine.table_name, "product_id", false) + ')'
  end

  def sql_for_status_id_field(field, operator, value)
    sql = ''
    case operator
    when "o"
      sql = "#{queried_table_name}.status_id IN (SELECT id FROM #{OrderStatus.table_name} WHERE is_closed=#{connection.quoted_false})" if field == "status_id"
    when "c"
      sql = "#{queried_table_name}.status_id IN (SELECT id FROM #{OrderStatus.table_name} WHERE is_closed=#{connection.quoted_true})" if field == "status_id"
    else
      sql_for_field(field, operator, value, queried_table_name, field)
    end
  end

  def order_count
    Order.visible.count(:include => query_includes, :conditions => statement)
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def order_amount
    Order.visible.sum(:amount, :include => query_includes, :conditions => statement, :group => "#{Order.table_name}.currency")
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def order_count_by_group
    r = nil
    if grouped?
      begin
        # Rails3 will raise an (unexpected) RecordNotFound if there's only a nil group value
        r = Order.visible.count(:joins => joins_for_order_statement(group_by_statement), :group => group_by_statement, :include => query_includes, :conditions => statement)
      rescue ActiveRecord::RecordNotFound
        r = {nil => order_count}
      end
      c = group_by_column
      if c.is_a?(QueryCustomFieldColumn)
        r = r.keys.inject({}) {|h, k| h[c.custom_field.cast_value(k)] = r[k]; h}
      end
    end
    r
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def results_scope(options={})
    order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)
    scope = Order.visible
    options[:search].split(' ').collect{ |search_string| scope = scope.live_search(search_string) } unless options[:search].blank?
    scope.includes(query_includes).
      where(statement).
      order(order_option).
      joins(joins_for_order_statement(order_option.join(',')))
  end

  def query_includes
    includes = [:status, :project]
    includes << {:contact => :address} if self.filters["contact_country"] ||
        self.filters["contact_city"] ||
        [:contact_country, :contact_city].include?(group_by_column.try(:name))
    includes << :products if self.filters["products"]
    includes << group_by_column.try(:name) if group_by_column && ![:contact_country, :contact_city].include?(group_by_column.name)
    includes
  end

end
