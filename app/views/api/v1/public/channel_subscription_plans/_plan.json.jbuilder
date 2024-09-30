# frozen_string_literal: true

json.extract! model, :id, :active, :nickname, :trial_period_days, :amount, :currency, :interval, :interval_count,
              :im_replays, :im_livestreams, :im_uploads, :im_interactives, :im_channel_conversation, :im_name
json.formatted_price model.formatted_price
json.period model.period
