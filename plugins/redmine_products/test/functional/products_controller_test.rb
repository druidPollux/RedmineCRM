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

require File.expand_path('../../test_helper', __FILE__)

class ProductsControllerTest < ActionController::TestCase
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
    assert_not_nil assigns(:products)
  end

  def test_get_index_in_project
    @request.session[:user_id] = 1
    get :index, :project_id => 1
    assert_response :success
    assert_template :index
    assert_not_nil assigns(:products)
  end

  def test_get_new
    @request.session[:user_id] = 1
    get :new, :project_id => 1
    assert_response :success
    assert_template :new
    assert_not_nil assigns(:product)
  end

  def test_get_edit
    @request.session[:user_id] = 1
    get :edit, :id => 1
    assert_response :success
    assert_template :edit
    assert_not_nil assigns(:product)
    assert_select 'div.box.tabular' do
      assert_select 'p.product-name' do
        assert_select 'input[value=?]', "CRM"
      end
    end
  end

  def test_get_show
    @request.session[:user_id] = 1
    get :show, :id => 1
    assert_response :success
    assert_template :show
    assert_not_nil assigns(:product)

    assert_select 'div.product' do
      assert_select 'table.subject_header' do
        assert_select 'li.price', "$500.00"
      end
    end
  end

  def test_post_create
    @request.session[:user_id] = 1

    assert_difference 'Product.count' do
      post :create, :project_id => 1,
        :product => {:code => "PR-001",
                     :name => "New product",
                     :project_id => "1",
                     :tag_list => ["new", "tag"],
                     :status_id => Product::ACTIVE_PRODUCT}
    end
    assert_redirected_to :controller => 'products', :action => 'show', :id => Product.last.id

    order = Product.find_by_code("PR-001")
    assert_not_nil order
    assert_equal "New product", order.name
    assert_equal ["new", "tag"].uniq.sort, order.tag_list.uniq.sort
    assert_equal Product::ACTIVE_PRODUCT, order.status_id
  end

  def test_put_update
    @request.session[:user_id] = 1

    put :update, :id => 1,
      :product => {:code => "PR-001-updated",
                   :name => "Updated product",
                   :status_id => Product::INACTIVE_PRODUCT}

    assert_redirected_to :controller => 'products', :action => 'show', :id => 1

    order = Product.find(1)
    assert_not_nil order
    assert_equal "PR-001-updated", order.code
    assert_equal "Updated product", order.name
    assert_equal Product::INACTIVE_PRODUCT, order.status_id
  end

  def test_destroy
    @request.session[:user_id] = 1

    assert_difference 'Product.count', -1 do
      delete :destroy, :id => 1
    end
  end

end
