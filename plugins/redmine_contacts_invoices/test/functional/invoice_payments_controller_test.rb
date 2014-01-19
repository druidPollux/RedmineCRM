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

class InvoicePaymentsControllerTest < ActionController::TestCase
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
                             :notes,
                             :roles,
                             :enabled_modules,
                             :tags,
                             :taggings])   

    ActiveRecord::Fixtures.create_fixtures(Redmine::Plugin.find(:redmine_contacts_invoices).directory + '/test/fixtures/', 
                          [:invoices,
                           :invoice_lines,
                           :invoice_payments
                           ])

  def setup
    RedmineInvoices::TestCase.prepare
    Project.find(1).enable_module!(:contacts_invoices)
    
    User.current = nil  
  end
  
  def test_should_get_new
    @request.session[:user_id] = 1
    
    get :new, :invoice_id => 1
    assert_response :success
    assert_template :new
    assert_not_nil assigns(:invoice)
    assert_not_nil assigns(:invoice_payment)
  end  

  def test_should_post_create
    @request.session[:user_id] = 1
    invoice = Invoice.find(2)
    invoice.calculate_amount
    invoice.calculate_balance
    invoice.save!

    assert_difference 'Invoice.find(2).remaining_balance', -10 do
      post :create, :invoice_id => 2, :invoice_payment => {:amount => 10.0, :payment_date => Date.today, :description => "New partial payment"}
      assert_response :redirect
      invoice = Invoice.find(2)
      payment = invoice.payments.last
      assert_equal 10, payment.amount
    end

  end  

  def test_should_post_create_paid
    @request.session[:user_id] = 1
    invoice = Invoice.find(2)
    invoice.calculate_amount
    invoice.calculate_balance
    invoice.save!
    assert_difference 'Invoice.find(2).remaining_balance', -4695 do
      post :create, :invoice_id => 2, :invoice_payment => {:amount => 4695.0, :payment_date => Date.today, :description => "New full payment"}
      assert_response :redirect
      assert_equal 4695, InvoicePayment.find_by_description("New full payment").amount
      assert Invoice.find(2).is_paid?
    end

  end 

  def test_should_delete_destroy
    @request.session[:user_id] = 1
    assert_difference 'InvoicePayment.count', -1 do
      delete :destroy, :invoice_id => 1, :id => 1
    end
  end    

end
