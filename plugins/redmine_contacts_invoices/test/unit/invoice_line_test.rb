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

class InvoiceLineTest < ActiveSupport::TestCase

  def test_accepts_numbers_with_commas
    line = InvoiceLine.new(:description => 'desc', :price => '123,45', :quantity => '1,2')
    assert line.valid?, 'Should be valid'
    assert_equal line.price, 123.45
    assert_equal line.quantity, 1.2
  end

  def test_should_not_accepts_empty_numbers
    line = InvoiceLine.new(:description => 'desc', :price => '123,45', :quantity => '')
    assert !line.valid?, 'Should be valid'
  end  
end
