module Pivotal
  class WebhookMessage
    attr_accessor :message
    def initialize message
      self.message = Nokogiri::XML(message)
    end

    def description
      message.xpath("/activity/description").text
    end 

    def story_id
      message.xpath('/activity/stories/story/id').text
    end

    def story_url
      "https://www.pivotaltracker.com/story/show/#{story_id}"
    end

  end
end