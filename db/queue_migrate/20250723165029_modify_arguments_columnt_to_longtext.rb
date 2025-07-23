class ModifyArgumentsColumntToLongtext < ActiveRecord::Migration[7.1]
  def change
    execute "ALTER TABLE solid_queue_jobs MODIFY arguments LONGTEXT"
  end
end
