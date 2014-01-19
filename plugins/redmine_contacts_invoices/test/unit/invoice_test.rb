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

class InvoiceTest < ActiveSupport::TestCase
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
                             :roles,
                             :enabled_modules])   

    ActiveRecord::Fixtures.create_fixtures(Redmine::Plugin.find(:redmine_contacts_invoices).directory + '/test/fixtures/', 
                          [:invoices,
                           :invoice_lines])
  def setup
    @project_a = Project.create(:name => "Test_a", :identifier => "testa")
    @project_b = Project.create(:name => "Test_b", :identifier => "testb")

    @contact1 = Contact.create(:first_name => "Contact_1", :projects => [@project_a])
    @invoice1 = Invoice.create(:number => "INV/20121212-1", :contact => @contact1, :project => @project_a, :status_id => Invoice::DRAFT_INVOICE, :invoice_date => Time.now)

    @issue_1 = Issue.create(:project_id => 1, :tracker_id => 1, :author_id => 1,
                         :status_id => 1, :priority => IssuePriority.first,
                         :subject => 'Invoice Issue 1')
    @issue_2 = Issue.create(:project_id => 1, :tracker_id => 1, :author_id => 3,
                         :status_id => 1, :priority => IssuePriority.first,
                         :subject => 'Invoice Issue 2')

    @time_entrie_1 = @issue_1.time_entries.create(:spent_on => '2012-12-12',
                                :hours    => 10,
                                :user     => User.find(1),
                                :activity => TimeEntryActivity.first)
    @time_entrie_2 = @issue_1.time_entries.create(:spent_on => '2012-12-13',
                                :hours    => 5,
                                :user     => User.find(2),
                                :activity => TimeEntryActivity.first)
    @time_entrie_3 = @issue_2.time_entries.create(:spent_on => '2012-12-12',
                                :hours    => 12,
                                :user     => User.find(2),
                                :activity => TimeEntryActivity.first)    
  end
  
  def test_should_calculate_amount
    @invoice1.lines.new(:description => "Line 1", :quantity => 1, :price => 10)
    @invoice1.lines.new(:description => "Line 2", :quantity => 2, :price => 20)
    @invoice1.calculate_amount
    # assert @invoice1.save!
    assert_equal 2, @invoice1.lines.size
    assert_equal 50, @invoice1.amount.to_i
  end

  def test_should_calculate_amount_before_save
    @invoice1.lines.new(:description => "Line 1", :quantity => 1, :price => 10)
    @invoice1.lines.new(:description => "Line 2", :quantity => 2, :price => 20)
    assert @invoice1.save
    assert_equal 2, @invoice1.lines.size
    assert_equal 50, @invoice1.amount.to_i
  end

  def test_should_calculate_amount_before_destroy_line
    @invoice1.lines.create(:description => "Line 1", :quantity => 1, :price => 10)
    @invoice1.lines.create(:description => "Line 2", :quantity => 2, :price => 20)
    assert @invoice1.save
    assert_equal 50, @invoice1.amount.to_i
    @invoice1.lines.last.destroy
    @invoice1.reload
    assert_equal 10, @invoice1.amount.to_i
  end

end
