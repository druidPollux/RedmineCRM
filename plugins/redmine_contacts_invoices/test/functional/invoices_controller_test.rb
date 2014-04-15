# encoding: utf-8
#
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

require File.expand_path('../../test_helper', __FILE__)

class InvoicesControllerTest < ActionController::TestCase
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

    ActiveRecord::Fixtures.create_fixtures(Redmine::Plugin.find(:redmine_contacts_invoices).directory + '/test/fixtures/',
                          [:invoices,
                           :invoice_lines])

  # TODO: Test for delete tags in update action

  def setup
    RedmineInvoices::TestCase.prepare
    Project.find(1).enable_module!(:contacts_invoices)

    User.current = nil
  end

  test "should get index" do
    # log_user('admin', 'admin')
    @request.session[:user_id] = 1
    Setting.default_language = 'en'

    get :index
    assert_response :success
    assert_template :index
    assert_not_nil assigns(:invoices)
    assert_nil assigns(:project)
  end

  def test_get_index_with_sorting
    @request.session[:user_id] = 1
    RedmineInvoices.settings[:invoices_excerpt_invoice_list] = 1
    get :index, :sort => "invoices.number:desc"
    assert_response :success
    assert_template :index
  end

  test "should get index in project" do
    # log_user('admin', 'admin')
    @request.session[:user_id] = 1
    Setting.default_language = 'en'

    get :index, :project_id => 1
    assert_response :success
    assert_template :index
    assert_not_nil assigns(:invoices)
    assert_not_nil assigns(:project)
  end

  test "should get index deny user in project" do
    @request.session[:user_id] = 4
    get :index, :project_id => 1
    assert_response :forbidden
  end

  test "should get index with empty settings" do
    # log_user('admin', 'admin')
    @request.session[:user_id] = 1
    Setting.plugin_redmine_contacts_invoices = nil
    Setting.default_language = 'en'

    get :index
    assert_response :success
    assert_template :index
  end

  test "should get index with filters" do
    @request.session[:user_id] = 2
    get :index, :status_id => 1
    assert_response :success
    assert_template :index
    assert_select '.invoice_list td.number a', '1/001'
    assert_select '.invoice_list td.number a', {:count => 0, :text => '1/002'}
  end

  test "should get index with sorting" do
    @request.session[:user_id] = 1
    get :index, :sort => "amount"
    assert_response :success
    assert_template :index
  end

  test "should get show" do
    # RedmineInvoices.settings[:total_including_tax] = true
    # log_user('admin', 'admin')
    @request.session[:user_id] = 1
    Setting.default_language = 'en'

    Invoice.find(1).save

    get :show, :id => 1
    assert_response :success
    assert_template :show
    assert_not_nil assigns(:invoice)
    assert_not_nil assigns(:project)

    assert_select 'div.subject h3', "Domoway - $3 321.00"
    assert_select 'div.invoice-lines table.list tr.line-data td.description', "Consulting work"
  end

  def test_get_show_as_pdf
    @request.session[:user_id] = 1
    Setting.default_language = 'en'

    get :show, :id => 1, :format => 'pdf'
    assert_response :success
    assert_not_nil assigns(:invoice)
    assert_equal 'application/pdf', @response.content_type
  end

  def test_should_get_show_as_pdf_without_client
    @request.session[:user_id] = 1
    Setting.default_language = 'en'
    Invoice.where(:id => 1).update_all(:contact_id => nil)
    get :show, :id => 1, :format => 'pdf'
    assert_response :success
    assert_not_nil assigns(:invoice)
    assert_equal 'application/pdf', @response.content_type
  end

  test "should get new" do
    @request.session[:user_id] = 2
    get :new, :project_id => 1
    assert_response :success
    assert_template 'new'
    assert_select 'input#invoice_number'
    assert_select 'textarea#invoice_lines_attributes_0_description'
  end

  test "should not get new by deny user" do
    @request.session[:user_id] = 4
    get :new, :project_id => 1
    assert_response :forbidden
  end


  test "should post create" do
    @request.session[:user_id] = 1
    assert_difference 'Invoice.count' do
      post :create, "invoice" => {"number"=>"1/005",
                                  "discount"=>"10",
                                  "lines_attributes"=>{"0"=>{"tax"=>"10",
                                                             "price"=>"140.0",
                                                             "quantity"=>"23.0",
                                                             "units"=>"products",
                                                             "_destroy"=>"",
                                                             "description"=>"Line one"}},
                                  "discount_type"=>"0",
                                  "contact_id"=>"1",
                                  "invoice_date"=>"2011-12-01",
                                  "due_date"=>"2011-12-03",
                                  "description"=>"Test description",
                                  "currency"=>"GBR",
                                  "status_id"=>"1"},
                    "project_id"=>"ecookbook"
    end
    assert_redirected_to :controller => 'invoices', :action => 'show', :id => Invoice.last.id

    invoice = Invoice.find_by_number('1/005')
    assert_not_nil invoice
    assert_equal 10, invoice.discount
    assert_equal "Line one", invoice.lines.first.description
  end

  test "should not post create by deny user" do
    @request.session[:user_id] = 4
    post :create, :project_id => 1,
        "invoice" => {"number"=>"1/005"}
    assert_response :forbidden
  end

  test "should get edit" do
    @request.session[:user_id] = 1
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:invoice)
    assert_equal Invoice.find(1), assigns(:invoice)
    assert_select 'textarea#invoice_lines_attributes_0_description', "Consulting work"
  end

  test "should put update" do
    @request.session[:user_id] = 1

    invoice = Invoice.find(1)
    old_number = invoice.number
    new_number = '2/001'

    put :update, :id => 1, :invoice => {:number => new_number}
    assert_redirected_to :action => 'show', :id => '1'
    invoice.reload
    assert_equal new_number, invoice.number
  end

  test "should post destroy" do
    @request.session[:user_id] = 1
    delete :destroy, :id => 1
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert_nil Invoice.find_by_id(1)
  end

  test "should bulk_destroy" do
    @request.session[:user_id] = 1
    assert_not_nil Invoice.find_by_id(1)
    delete :bulk_destroy, :ids => [1], :project_id => 'ecookbook'
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert_nil Invoice.find_by_id(1)
  end

  test "should bulk_update" do
    @request.session[:user_id] = 1
    put :bulk_update, :ids => [1, 2], :invoice => {:status_id => 2}
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert Invoice.find([1, 2]).all?{|e| e.status_id == 2}
  end

  test "should get context menu" do
    @request.session[:user_id] = 1
    xhr :get, :context_menu, :back_url => "/projects/ecookbok/invoices", :project_id => 'ecookbook', :ids => ['1', '2']
    assert_response :success
    assert_template 'context_menu'
  end

end

