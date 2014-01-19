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

class CreateOperations < ActiveRecord::Migration
  def change
    create_table :operations do |t|
      t.decimal :amount, :precision => 10, :scale => 2, :null => false
      t.integer :category_id, :null => false
      t.integer :account_id, :null => false
      t.integer :contact_id
      t.integer :comments_count
      t.timestamp :operation_date, :null => false
      t.integer :author_id, :null => false
      t.text :description
      t.timestamps
    end
  end
end
