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

class OperationRelation < ActiveRecord::Base
  unloadable

  belongs_to :operation_source, :class_name => 'Operation', :foreign_key => 'source_id'
  belongs_to :operation_destination, :class_name => 'Operation', :foreign_key => 'destination_id'

  validates_presence_of :operation_source, :operation_destination, :relation_type
  validates_uniqueness_of :destination_id, :scope => :source_id
  validate :validate_operation_relation

  def visible?(user=User.current)
    (operation_source.nil? || operation_source.visible?(user)) && (operation_destination.nil? || operation_destination.visible?(user))
  end

  def deletable?(user=User.current)
    visible?(user) &&
      ((operation_source.nil? || user.allowed_to?(:manage_operation_relations, operation_source.project)) ||
        (operation_destination.nil? || user.allowed_to?(:manage_operation_relations, operation_destination.project)))
  end

  def validate_operation_relation
    if operation_source && operation_destination
      errors.add :destination_id, :invalid if source_id == destination_id
      # detect circular dependencies depending wether the relation should be reversed
      errors.add :base, :circular_dependency if operation_destination.all_dependent_operations.include? operation_source
    end    
  end

  def other_operation(operation)
    (self.source_id == operation.id) ? operation_destination : operation_source
  end  

end
