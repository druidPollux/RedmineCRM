class CreateCmsMenus < ActiveRecord::Migration
  def change
    create_table :cms_menus do |t|
      t.string :name
      t.string :caption
      t.string :path
      t.integer :status_id
      t.integer :position
      t.string :menu_type
      t.integer :parent_id
      t.timestamps 
    end
  end
end
