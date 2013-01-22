Spree.user_class.class_eval do
  def self.garbage
    garbage_after = Spree::GarbageCleaner::Config.cleanup_days_interval
    self.joins("LEFT JOIN spree_orders ON spree_orders.user_id = #{Spree.user_class.table_name}.id").
      where("#{Spree.user_class.table_name}.email IS NULL OR #{Spree.user_class.table_name}.email LIKE ?", '%@example.net').
      where("#{Spree.user_class.table_name}.created_at <= ?", garbage_after.days.ago).
      where("spree_orders.completed_at IS NULL")
  end

  def garbage?
    garbage_after = Spree::GarbageCleaner::Config.cleanup_days_interval
    anonymous? && created_at <= garbage_after.days.ago && orders.count == orders.incomplete.count
  end
end
