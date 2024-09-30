# frozen_string_literal: true

json.extract! plan, :id, :active, :stripe_id, :trial_period_days, :nickname,
              :im_replays, :im_livestreams, :im_uploads, :im_interactives, :im_channel_conversation
json.amount plan.formatted_price
json.interval plan.period
