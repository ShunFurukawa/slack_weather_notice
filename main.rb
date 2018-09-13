require 'json'
require 'open-uri'
require 'slack/incoming/webhooks'

uri = 'http://weather.livedoor.com/forecast/webservice/json/v1?city=270000'

res          = JSON.load(open(uri).read)
title        = res['title']
description  = res['description']['text']
link         = res['link']
today        = res['forecasts'][0]
tomorrow     = res['forecasts'][1]
day_after_tomorrow = res['forecasts'][2]

def slack_notice text, attachments
  slack = Slack::Incoming::Webhooks.new ENV.fetch('WEBHOOK_URL')
  slack.post text, attachments: attachments
end

def temperature day, min_or_max
  temperature = day['temperature'][min_or_max]

  if temperature.nil?
    '--'
  else
    "#{temperature['celsius']}℃"
  end
end

def weather_of_the day, link
  min_temp = temperature day, 'min'
  max_temp = temperature day, 'max'

  title = "#{day['dateLabel']} の天気"
  text  = "*#{day['telop']}* \n    最低気温 #{min_temp} \n    最高気温 #{max_temp}"

  attachments = [{
    title: title,
    title_link: link,
    text: text,
    mrkdwn_in: [
      text
    ],
    image_url: day['image']['url'],
    color: '#04B404'
  }]

  slack_notice '', attachments
end

attachments = [{
  fallback: '大阪の天気予報',
  title: title,
  title_link: link,
  color: '#F35A00'
}]


slack_notice description, attachments
weather_of_the today, link
weather_of_the tomorrow, link
weather_of_the day_after_tomorrow, link

