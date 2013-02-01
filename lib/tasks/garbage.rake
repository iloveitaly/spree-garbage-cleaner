namespace :db do
  namespace :garbage do

    desc "Cleanup garbage by calling .destroy on every model marked as garbage"
    task :cleanup => :environment do
      # https://github.com/spree/spree/blob/1-2-stable/core/app/models/spree/order.rb#L202
      # shipping, and all other adjustments, are recalculated when the order is modified
      # this causes exceptions in some cases (e.g. when the shipping method's zone has
      # changed and the address on the order is no longer in the zone)

      Spree::Order.class_eval do
        old_update = instance_method(:update!)

        def update!
          begin
            old_update.bind(self).call
          rescue Exception => e
            puts "Error during Order#update!: #{e}"
          end
        end
      end

      config = Spree::GarbageCleaner::Config
      garbage_models = config.models_with_garbage.delete(' ').split(',').map(&:constantize)

      destroy_count = 0
      destroy_limit = ENV['DESTROY_LIMIT'].try(:to_i) || config.destroy_limit

      garbage_models.each do |model|
        until (garbage_bag = model.garbage.limit(config.batch_amount)).empty?
          destroy_count += garbage_bag.size
          printf "\rDestroying %i %s", destroy_count, model
          garbage_bag.destroy_all

          break if destroy_limit != 0 && destroy_count > destroy_limit
        end

        puts "Destroyed #{destroy_count} #{model}"
      end
    end

    desc "Gives some info about garbage inside the db"
    task :stats => :environment do
      garbage_models = Spree::GarbageCleaner::Config.models_with_garbage.delete(' ').split(',')

      longest_model_name = garbage_models.max { |a, b| a.length <=> b.length }

      puts "The following garbage records have been found:"
      garbage_models.each do |model|
        printf "%-#{longest_model_name.length}s ===> %i\n", model, model.constantize.garbage.count
      end
    end

  end
end