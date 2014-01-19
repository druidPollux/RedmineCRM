# Redmine - project management software
# Copyright (C) 2006-2012  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module Redmine
  module Acts
    module Attachable
      def self.included(base)
        base.extend ClassMethods
      end

      module InstanceMethods

        def attachments_visible?(user=User.current)
          !self.respond_to?(:project) || 
          ((respond_to?(:visible?) ? visible?(user) : true) &&
                      user.allowed_to?(self.class.attachable_options[:view_permission], self.project))
        end

        def attachments_deletable?(user=User.current)
          !self.respond_to?(:project) || 
          ((respond_to?(:visible?) ? visible?(user) : true) &&
                      user.allowed_to?(self.class.attachable_options[:delete_permission], self.project)) 
        end

        module ClassMethods
        end
      end
    end
  end
end
