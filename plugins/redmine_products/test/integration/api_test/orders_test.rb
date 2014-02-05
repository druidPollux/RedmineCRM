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

require File.dirname(__FILE__) + '/../../test_helper'

class Redmine::ApiTest::OrdersTest < ActionController::IntegrationTest
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


  def setup
    Setting.rest_api_enabled = '1'
    @project_1 = Project.find(1)
    @project_2 = Project.find(5)
    EnabledModule.create(:project => @project_1, :name => 'orders')
    EnabledModule.create(:project => @project_1, :name => 'products')
    EnabledModule.create(:project => @project_2, :name => 'orders')
    EnabledModule.create(:project => @project_2, :name => 'products')
  end

  def test_get_orders_xml
    # Use a private project to make sure auth is really working and not just
    # only showing public issues.
    Redmine::ApiTest::Base.should_allow_api_authentication(:get, "/projects/private-child/orders.xml")

    get '/orders.xml', {}, credentials('admin')

    assert_tag :tag => 'orders',
      :attributes => {
        :type => 'array',
        :total_count => assigns(:orders_count),
        :limit => 25,
        :offset => 0
      }
  end


  def test_post_orders_xml
    parameters = {:order => {:project_id => 1, :number => 'api_test_002',
                             :order_date => Date.today,
                             :project_id => @project_1.id,
                             :status_id => OrderStatus.default,
                             :lines_attributes => {"0"=>{:description => "Test", :quantity => 2, :price => 10}}}}
    Redmine::ApiTest::Base.should_allow_api_authentication(:post,
                                    '/orders.xml',
                                    parameters,
                                    {:success_code => :created})

    assert_difference('Order.count') do
      post '/orders.xml', parameters, credentials('admin')
    end

    order = Order.first(:order => 'id DESC')
    assert_equal parameters[:order][:number], order.number

    assert_response :created
    assert_equal 'application/xml', @response.content_type
    assert_tag 'order', :child => {:tag => 'id', :content => order.id.to_s}
  end

  def test_put_orders_1_xml
    parameters = {:order => {:number => 'PO_UPDATED'}}

    Redmine::ApiTest::Base.should_allow_api_authentication(:put,
                                  '/orders/1.xml',
                                  parameters,
                                  {:success_code => :ok})

    assert_no_difference('Order.count') do
      put '/orders/1.xml', parameters, credentials('admin')
    end

    order = Order.find(1)
    assert_equal parameters[:order][:number], order.number

  end

end
