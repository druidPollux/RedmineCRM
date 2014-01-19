class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.string :name
      t.string :title
      t.string :summary
      t.string :keywords
      t.text :description
      t.text :content
      t.string :content_type      
      t.integer :status_id, :default => RedmineCms::STATUS_LOCKED
      t.integer :parent_id
      t.integer :project_id
      t.timestamps 
    end
    add_index :pages, :parent_id
  end
end
