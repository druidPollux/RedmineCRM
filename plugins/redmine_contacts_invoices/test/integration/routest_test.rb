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

class RoutingTest < ActionController::IntegrationTest

  test "invoices" do
    # REST actions
    assert_routing({ :path => "/invoices", :method => :get }, { :controller => "invoices", :action => "index" })
    assert_routing({ :path => "/invoices.xml", :method => :get }, { :controller => "invoices", :action => "index", :format => 'xml' })
    assert_routing({ :path => "/invoices/1", :method => :get }, { :controller => "invoices", :action => "show", :id => '1'})
    assert_routing({ :path => "/invoices/1/edit", :method => :get }, { :controller => "invoices", :action => "edit", :id => '1'})
    assert_routing({ :path => "/projects/23/invoices", :method => :get }, { :controller => "invoices", :action => "index", :project_id => '23'})
    assert_routing({ :path => "/projects/23/invoices.xml", :method => :get }, { :controller => "invoices", :action => "index", :project_id => '23', :format => 'xml'})
    assert_routing({ :path => "/projects/23/invoices.atom", :method => :get }, { :controller => "invoices", :action => "index", :project_id => '23', :format => 'atom'})

    assert_routing({ :path => "/invoices.xml", :method => :post }, { :controller => "invoices", :action => "create", :format => 'xml' })

    assert_routing({ :path => "/invoices/1.xml", :method => :put }, { :controller => "invoices", :action => "update", :format => 'xml', :id => "1" })

  end
  

end
