# This file is a part of Redmine Products (redmine_products) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2014 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_products is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_products is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_products.  If not, see <http://www.gnu.org/licenses/>.

module RedmineProducts
  module Patches
    module NotifiablePatch
      def self.included(base)
        base.extend(ClassMethods)
        base.class_eval do
            unloadable
            class << self
                alias_method_chain :all, :products
            end
        end
      end


      module ClassMethods
        # include ProductsHelper

        def all_with_products
          notifications = all_without_products
          notifications << Redmine::Notifiable.new('products_order_added')
          notifications << Redmine::Notifiable.new('products_order_comment_added')
          notifications << Redmine::Notifiable.new('products_order_updated')
          notifications
        end

      end

    end
  end
end

unless Redmine::Notifiable.included_modules.include?(RedmineProducts::Patches::NotifiablePatch)
  Redmine::Notifiable.send(:include, RedmineProducts::Patches::NotifiablePatch)
end
