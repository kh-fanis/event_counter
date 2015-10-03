class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.belongs_to :user,     null: false
      t.string     :title,    null: false
      t.datetime   :being_at, null: false
      t.string     :description
      t.boolean    :secret

      t.timestamps
    end
  end
end
