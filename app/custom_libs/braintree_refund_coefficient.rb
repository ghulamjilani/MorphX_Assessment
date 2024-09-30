# frozen_string_literal: true

# |         |             |
# |         |             |
# |  lost   |    lost     |        100%
# |  100%   |    50%      |       refund
# |         |             |
# |         |   credit    |       credit
# |         |   refund    |         or
# |         |    50%      |       money
# |         |             |
# o       4 hours       12 hours

# NOTE: the reason why it has "Braintree" in prefix is because it doesn't apply to sys credit purchases/trasactions
#      those are always fully refunded despite time
class BraintreeRefundCoefficient
  def initialize(model)
    raise ArgumentError, model.inspect unless model.is_a?(Session)

    @model = model
  end

  # example of how this method is used:
  # refund_amount = braintree_transaction.amount.to_f * @refund_coefficient.coefficient
  # if refund_amount > 0
  #   braintree_transaction.system_credit_refund!(refund_amount)
  # end
  def coefficient
    if could_be_full_refund_in_original_payment_type?
      # 0% credit loss
      1
    elsif @model.start_at < SystemParameter.half_credit_not_sooner_than_hours.to_i.hours.from_now
      # 100% credit loss
      0
    else
      # 50% credit loss
      0.5
    end
  end

  def could_be_full_refund_in_original_payment_type?
    @model.start_at > SystemParameter.full_money_or_credit_not_sooner_than_hours.to_i.hours.from_now
  end
end
