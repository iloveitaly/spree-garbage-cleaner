module Spree
  Order.class_eval do
    def self.destroy_garbage
      a = 0
      while true do
        puts "\rOrders: deleting #{a * 100}"
        g = self.garbage

        break if g.empty?
        g.destroy_all
        a += 1
      end
    end

    def self.garbage
      garbage_after = Spree::GarbageCleaner::Config.cleanup_days_interval
      self.incomplete.where("created_at <= ?", garbage_after.days.ago).limit(100)
    end

    def garbage?
      garbage_after = Spree::GarbageCleaner::Config.cleanup_days_interval
      completed_at.nil? && created_at <= garbage_after.days.ago
    end
  end
end