# frozen_string_literal: true

class GloballyUniqueSlugGenerator
  # The slug generator offers functionality to check slug candidates for availability.
  def initialize(scope, config)
    @scope = scope
    @config = config
  end

  def available?(slug)
    return false if @scope.klass.to_s == 'Organization' && !User.where(slug: slug).count.zero?
    return false if @scope.klass.to_s == 'User' && !Organization.where(slug: slug).count.zero?

    # NOTE: just checking FriendlyId::Slug-s for user slug validation is not enough because it doesn't create FriendlyId::Slug(history option is disabled)
    # NOTE: only channels and sessions create FriendlySlug's
    @scope.where(slug: slug).blank? && FriendlyId::Slug.where(slug: slug).blank?
  end

  def generate(candidates)
    candidates.detect { |c| available?(c) } || resolve_friendly_id_conflict(candidates.first)
  end

  private

  def resolve_friendly_id_conflict(candidate_str)
    res = [candidate_str, rand(1000)].compact.join('-')

    cb = proc { |_e| res = [candidate_str, rand(1000)].compact.join('-') }
    # retry 7 times
    Retryable.retryable(tries: 7, on: ArgumentError, exception_cb: cb) do
      raise ArgumentError unless available?(res)
    end
    res
  end
end
