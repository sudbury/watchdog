require_relative 'Notifier'

class SlackNotifier < Notifier
  def initialize(options = {})
    @notifier = Slack::Notifier.new options[:webhook]
    @notifier.channel  = options[:channel] ||= '#general'
    @notifier.username = options[:username] ||= 'Watchdog'
    @icon_emoji = options[:icon_emoji] ||= ':bell:'
  end

  # message: string
  # type: one of '', 'good', 'warning', or 'danger'
  # attachments: array of extra pieces of information. Will be wrapped in blocks
  def send(message, type = '', attachments = [])
    puts "Pining Slack with message #{message}".yellow
    if attachments.empty?
      attachments = [{
          fallback: message,
          text: message,
          color: type
        }]
        message = ''
    else
      attachments.map! do |attachment|
        {
          fallback: attachment,
          text: attachment,
          color: type
        }
      end
    end
    @notifier.ping message, icon_emoji: @icon_emoji, attachments: attachments
  end
end
