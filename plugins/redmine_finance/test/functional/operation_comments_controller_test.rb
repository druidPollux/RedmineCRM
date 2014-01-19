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

class OperationCommentsControllerTest < ActionController::TestCase
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
                           :comments,
                           :enabled_modules,
                           :operation_categories])

  def setup
    Project.find(1).enable_module!(:finance)
  end

  def test_should_destroy
    @request.session[:user_id] = 1
    assert_not_nil Comment.find(3)
    assert_difference 'Comment.count', -1 do
      delete :destroy, :id => 1, :comment_id => 3
    end    
    assert_response :redirect
  end   

  def test_should_post_create
    @request.session[:user_id] = 1
    post :create, :id => 1, :comment => { :comments => 'This is a test operation comment' }
    assert_redirected_to '/operations/1'

    comment = Operation.find(1).comments.last
    assert_not_nil comment
    assert_equal 'This is a test operation comment', comment.comments
    assert_equal User.find(1), comment.author

  end  

end
