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

class CreateInvoicesAndExpenses < ActiveRecord::Migration
  def self.up
    create_table :invoices do |t|
      t.string :number
      t.datetime :invoice_date
      t.decimal :discount, :precision => 10, :scale => 2, :default => 0, :null => false
      t.integer :discount_type, :default => 0, :null => false
      t.text :description
      t.datetime :due_date
      t.string :language
      t.string :currency, :size => 3
      t.integer :status_id
      t.integer :contact_id
      t.integer :project_id
      t.integer :assigned_to_id
      t.integer :author_id
      t.timestamps
    end
    add_index :invoices, :contact_id 
    add_index :invoices, :project_id
    add_index :invoices, :status_id
    add_index :invoices, :assigned_to_id
    add_index :invoices, :author_id

    create_table :expenses do |t|
      t.date :expense_date
      t.decimal :price, :precision => 10, :scale => 2, :default => 0, :null => false
      t.text :description
      t.integer :contact_id
      t.integer :author_id
      t.integer :project_id
      t.integer :status_id
      t.timestamps
    end
    add_index :expenses, :contact_id 
    add_index :expenses, :project_id
    add_index :expenses, :status_id
    add_index :expenses, :author_id    
  end

  def self.down
    drop_table :invoices
  end
end
