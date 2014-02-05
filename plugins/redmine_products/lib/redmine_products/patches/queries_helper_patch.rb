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

require_dependency 'queries_helper'

module RedmineProducts
  module Patches
    module QueriesHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method_chain :column_value, :products
        end
      end


      module InstanceMethods
        # include ContactsHelper

        def column_value_with_products(column, issue, value)
          case value.class.name
          when 'String'
            if [:order_number, :order_subject].include?(column.name)
              link_to(h(value), :controller => 'orders', :action => 'show', :id => issue)
            elsif [:contact_city, :contact_country].include?(column.name)
              value
            else
              column_value_without_products(column, issue, value)
            end
          when 'BigDecimal'
            if column.name == :order_amount
              issue.amount_to_s
            end
          when 'Product'
            product_tag(value, :size => 16)
          else
            column_value_without_products(column, issue, value)
          end
        end

      end

    end
  end
end

unless QueriesHelper.included_modules.include?(RedmineProducts::Patches::QueriesHelperPatch)
  QueriesHelper.send(:include, RedmineProducts::Patches::QueriesHelperPatch)
end
