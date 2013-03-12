require 'cinch'
require 'nokogiri'
require 'pivotal'
require 'pivotal-tracker'

$nick = ENV.fetch('nick', "pivotal-bot")
$irc_server = ENV.fetch('IRC', "irc.freenode.org")
$channel = ENV.fetch('channel', nil)
$project = ENV.fetch('project', nil)
$token = ENV.fetch('token', nil)

PivotalTracker::Client.token = $token if $token

def project
  return unless $token and $project
  @project ||= PivotalTracker::Project.find $project
end

bot = Cinch::Bot.new do
  configure do |c|
  	c.nick = $nick
    c.server = $irc_server
    c.channels = [$channel]
  end

  on :message, "hello" do |m|
    m.reply "Hello, #{m.user.nick}"
  end

  on :message, /story\/show\/([0-9]+)/ do |m, ticket_id|
    story = project.stories.find(ticket_id)
    m.reply "#{story.story_type}: #{story.name} (#{story.current_state}) / owner: #{story.owned_by}"
  end
end

Thread.new {
  bot.start
}

# Pivotal Activity Web Hook documentation:
#   https://www.pivotaltracker.com/help/integrations?version=v3#activity_web_hook
post '/' do 
  message = Pivotal::WebhookMessage.new request.body.read
  bot.channel_list.msg("#{message.description} #{message.story_url}")
end

