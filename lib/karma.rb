require 'cinch'
require 'dbm'
require 'thread'
$karma_semaphore = Mutex.new

class Karma
  include Cinch::Plugin

 set :prefix, ""

  attr_reader :database

  def initialize(*args)
    super

    @database = DBM.open('karma', nil, DBM::WRCREAT)
  end

  match /(\S+)\+\+/, method: :increment
  def increment(m, thing)
    $karma_semaphore.synchronize {
      @database[thing] = @database[thing].to_i + 1
      @database[thing + "_inc"] = @database[thing + "_inc"].to_i + 1
    }
  end

  match /(\S+)--/, method: :decrement
  def decrement(m, thing)
     
    $karma_semaphore.synchronize {
      @database[thing] = @database[thing].to_i - 1
      @database[thing + "_dec"] = @database[thing + "_dec"].to_i + 1
    }
  end

  match /^@karma?(\s+)?(\S+)?/, method: :show_scores
  def show_scores(m, whitespace, thing, n=3)
    if thing
      m.reply "Karma for #{thing} has been increased #{@database[thing + "_inc"].to_i} times and decreased #{@database[thing + "_dec"].to_i} times for a total karma of #{@database[thing].to_i}."
    else
      sorted_things = @database.reject { |k, v| k =~ /(_inc|_dec)$/} .to_hash.sort_by { |k, v| v.to_i }
      top_scores   = sorted_things.reverse.take(n)
      m.reply "Highest karma: #{top_scores.map { |thing, value| "#{thing} (#{value})" }.join(", ")}"
      last_scores   = sorted_things.take(n).reverse
      m.reply "Lowest karma: #{last_scores.map { |thing, value| "#{thing} (#{value})" }.join(", ")}"
    end
  end

  def update_user(thing)
    yield(thing)
    save
  end
end
