class AddVisibilityToMenusAndPages < ActiveRecord::Migration
  def change
    add_column :cms_menus, :visibility, :string
    add_column :pages, :visibility, :string
    add_index :cms_menus, :visibility
    add_index :pages, :visibility
  end
end