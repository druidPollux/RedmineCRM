# encoding: utf-8
#
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

# encoding: utf-8
require File.expand_path('../../test_helper', __FILE__)

class OrdersControllerTest < ActionController::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries

    ActiveRecord::Fixtures.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/',
                            [:contacts,
                             :contacts_projects])

    ActiveRecord::Fixtures.create_fixtures(Redmine::Plugin.find(:redmine_products).directory + '/test/fixtures/',
                          [:products,
                           :order_statuses,
                           :orders,
                           :product_lines])

    ActiveRecord::Fixtures.create_fixtures(Redmine::Plugin.find(:redmine_contacts_invoices).directory + '/test/fixtures/',
                          [:invoices,
                           :invoice_lines]) if ProductsSettings.invoices_plugin_installed?

  def setup
    @project_1 = Project.find(1)
    @project_2 = Project.find(5)
    EnabledModule.create(:project => @project_1, :name => 'orders')
    EnabledModule.create(:project => @project_1, :name => 'products')
    EnabledModule.create(:project => @project_2, :name => 'orders')
    EnabledModule.create(:project => @project_2, :name => 'products')
  end

  def test_get_index
    @request.session[:user_id] = 1
    get :index
    assert_response :success
    assert_template :index
    assert_not_nil assigns(:orders)
  end

  def test_get_index_in_project
    @request.session[:user_id] = 1
    get :index, :project_id => 1
    assert_response :success
    assert_template :index
    assert_not_nil assigns(:orders)
  end

  def test_index_with_project_and_contact_country_filter
    @request.session[:user_id] = 1
    get :index, :project_id => 1, :set_filter => 1,
      :f => ['contact_country'],
      :op => {'contact_country' => '='},
      :v => {'contact_country' => ['RU']}
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:orders)

    query = assigns(:query)
    assert_not_nil query
    assert_equal({'contact_country' => {:operator => '=', :values => ['RU']}}, query.filters)
  end

  def test_index_with_search_filter
    @request.session[:user_id] = 1
    xhr :post, :index, :search => "Sales order for plugin Finance"
    assert_response :success
    assert_template '_list'
    assert_not_nil assigns(:orders)
    assert_tag :tag => 'a', :content => /#27 - Sales order for plugin Finance/
  end

  def test_index_with_project_and_contact_country_filter_and_grouping
    @request.session[:user_id] = 1
    get :index, :project_id => 1, :set_filter => 1,
      :f => ['contact_country'],
      :op => {'contact_country' => '='},
      :v => {'contact_country' => ['RU']},
      :group_by => "project"
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:orders)

    query = assigns(:query)
    assert_not_nil query
    assert_equal({'contact_country' => {:operator => '=', :values => ['RU']}}, query.filters)
  end

  def test_index_with_products_filter
    @request.session[:user_id] = 1
    get :index, :set_filter => 1,
      :f => ['products'],
      :op => {'products' => '='},
      :v => {'products' => ['1']}
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:orders)

    query = assigns(:query)
    assert_not_nil query
    assert_equal({'products' => {:operator => '=', :values => ['1']}}, query.filters)
  end

  def test_get_new
    @request.session[:user_id] = 1
    get :new, :project_id => 1
    assert_response :success
    assert_template :new
    assert_not_nil assigns(:order)
  end

  def test_get_show
    @request.session[:user_id] = 1
    get :show, :id => 1
    assert_response :success
    assert_template :show
    assert_not_nil assigns(:order)

    assert_select 'table.product-lines' do
      assert_select 'tr.total' do
        assert_select 'th.total_units', "20.0"
        assert_select 'th.subtotal_amount', "$6 571.00"
        assert_select 'th.tax_amount', "$71.20"
        assert_select 'th.total_amount', "$6 642.00"
      end
    end
  end

  def test_destroy_order_and_product_lines
    @request.session[:user_id] = 1

    assert_difference 'Order.count', -1 do
      assert_difference 'ProductLine.count', -5 do
        delete :destroy, :id => 1, :todo => 'destroy'
      end
    end
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert_nil Order.find_by_id(1)
    assert_nil ProductLine.find_by_id([6, 11, 12, 16, 21])
  end

  def test_post_create
    @request.session[:user_id] = 1

    assert_difference 'Order.count' do
      post :create, :project_id => 1,
        :order => {:number => "SO-001",
                   :subject => "New sales order",
                   :project_id => "1",
                   :contact_id => "3",
                   :order_date => "2013-11-04",
                   :status_id => "2",
                   :currency => "USD",
                   :assigned_to_id => "3",
                   :description => "*Order #SO-001 description with textile*",
                   :lines_attributes => {"0" => {:product_id => "4",
                                                 :description => "People plugin with discount",
                                                 :quantity => "2",
                                                 :price => "99",
                                                 :tax => "0.0",
                                                 :discount => "10",
                                                 :_destroy => false,
                                                 :position => ""},
                             "1383550516006" => {:product_id => "6",
                                                 :description => "Questions plugin with tax",
                                                 :quantity => "1",
                                                 :price => "99",
                                                 :tax => "20",
                                                 :discount => "",
                                                 :_destroy => false,
                                                 :position => ""},
                             "1383550542085" => {:product_id => "",
                                                 :description => "Delivery",
                                                 :quantity => "1",
                                                 :price => "30",
                                                 :tax => "0.0",
                                                 :discount => "",
                                                 :_destroy => false,
                                                 :position => ""}
                                        }
                   }
    end
    assert_redirected_to :controller => 'orders', :action => 'show', :id => Order.last.id

    order = Order.find_by_number("SO-001")
    assert_not_nil order
    assert_equal 1, order.author_id
    assert_equal 3, order.contact_id
    assert_equal 2, order.status_id
    assert_equal 3, order.total_units
    assert_equal Date.parse("2013-11-04"), order.order_date.to_date
  end

  def test_put_update
    @request.session[:user_id] = 1
    put :update, :id => 1,
      :order => {:number => "SO-002",
                 :subject => "Updated sales order",
                 :project_id => "5",
                 :contact_id => "3",
                 :order_date => "2013-11-04",
                 :status_id => "2",
                 :currency => "EUR",
                 :assigned_to_id => "3",
                 :description => "Order #SO-002 description with textile",
                 :lines_attributes => {"0" => {:id => 6,
                                               :product_id => "4",
                                               :description => "People plugin with discount",
                                               :quantity => "2",
                                               :price => "20",
                                               :tax => "0.0",
                                               :discount => "10",
                                               :_destroy => false,
                                               :position => ""},
                                      "1" => {:id => "11", :_destroy => "1"},
                                      "2" => {:id => "12", :_destroy => "1"},
                                      "3" => {:id => "16", :_destroy => "1"},
                                      "4" => {:id => "21", :_destroy => "1"},
                          "1383550542085" => {:product_id => "",
                                               :description => "Delivery",
                                               :quantity => "1",
                                               :price => "30",
                                               :tax => "0.0",
                                               :discount => "",
                                               :_destroy => false,
                                               :position => ""}
                                      }
                 }
    assert_redirected_to :controller => 'orders', :action => 'show', :id => 1

    order = Order.find(1)
    assert_not_nil order
    assert_equal "SO-002", order.number
    assert_equal "Updated sales order", order.subject
    assert_equal 5, order.project_id
    assert_equal 2, order.status_id
    assert_equal 2, order.lines.count
    assert_equal 2, order.total_units.to_f
  end



end
