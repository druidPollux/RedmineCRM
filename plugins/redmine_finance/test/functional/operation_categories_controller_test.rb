# encoding: utf-8
#
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

require File.expand_path('../../test_helper', __FILE__)

class OperationCategoriesControllerTest < ActionController::TestCase
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
                             :contacts_projects,
                             :contacts_issues,
                             :deals,
                             :notes,
                             :roles,
                             :enabled_modules,
                             :tags,
                             :taggings,
                             :contacts_queries])

    if RedmineFinance.invoices_plugin_installed?
      ActiveRecord::Fixtures.create_fixtures(Redmine::Plugin.find(:redmine_contacts_invoices).directory + '/test/fixtures/',
                            [:invoices,
                             :invoice_lines])
    end

    ActiveRecord::Fixtures.create_fixtures(Redmine::Plugin.find(:redmine_finance).directory + '/test/fixtures/',
                          [:accounts,
                           :operations,
                           :enabled_modules,
                           :operation_categories])

  def setup
    @request.session[:user_id] = 1
    Project.find(1).enable_module!(:finance)
  end

  def test_should_get_new
    get :new
    assert_response :success
    assert_template :new
    assert_not_nil assigns(:category)
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
    assert_template :edit
    assert_not_nil assigns(:category)
  end

  def test_should_put_update
    put :update, :id => 1, :category => {:name => "Changed category name"}
    assert_response :redirect
    assert_equal "Changed category name", OperationCategory.find(1).name
  end

  def test_should_post_create
    post :create, :category => {:name => "New category name", :is_income => true}
    assert_response :redirect
    assert_equal "New category name", OperationCategory.last.name
    assert_equal true, OperationCategory.last.is_income?
  end

  def test_destroy_category_not_in_use
    new_category = OperationCategory.create(:name => "Destroyable", :is_income => false)
    assert_difference 'OperationCategory.count', -1 do
      delete :destroy, :id => new_category.id
    end
    assert_redirected_to '/settings/plugin/redmine_finance?tab=operation_categories'
  end

  def test_destroy_category_in_use
    assert_not_nil Operation.find_by_category_id(1)

    assert_no_difference 'OperationCategory.count' do
      delete :destroy, :id => '1'
    end
    assert_redirected_to '/settings/plugin/redmine_finance?tab=operation_categories'
    assert_not_nil OperationCategory.find_by_id(1)

  end

end
