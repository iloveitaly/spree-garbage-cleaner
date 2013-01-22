namespace :db do
  namespace :garbage do

    desc "Cleanup garbage by calling .destroy on every model marked as garbage"
    task :cleanup => :environment do
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