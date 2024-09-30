# frozen_string_literal: true

module AbilityLib
  class AdminAbility
    include CanCan::Ability

    def initialize(user)
      can :read, ActiveAdmin::Page, name: 'Dashboard'
      can :read, ActiveAdmin::Page, name: 'RevenueOrganization'
      can :csv, ActiveAdmin::Page, name: 'RevenueOrganization'
      can :update, ActiveAdmin::Page, name: 'RevenueOrganization'

      can :manage, ::PageBuilder::AdBanner
      can :manage, AdClick
      can :manage, Booking::Booking
      can :manage, Booking::BookingCategory
      can :manage, Booking::BookingPrice
      can :manage, Booking::BookingSlot
      can :manage, Channel
      can :manage, Document
      can :manage, DocumentMember
      can :manage, Organization
      can :read, PaymentTransaction
      can :refund, PaymentTransaction
      can :manage, Payout
      can :manage, Poll::Poll
      can :manage, Poll::Template::Poll
      can :manage, Poll::Option
      can :manage, Poll::Vote
      can :read, ::StripeDb::Subscription
      can :cancel, ::StripeDb::Subscription
      can :read, ::StripeDb::ServiceSubscription
      can :upgrade, ::StripeDb::ServiceSubscription
      can :cancel, ::StripeDb::ServiceSubscription
      can :read, ::StripeDb::ServicePlan
      can :read, ::FreePlan
      can :read, ::FreeSubscription
      can :read, ::Partner::Plan
      can :read, ::Partner::Subscription
      can :read, PlanPackage
      can :manage, Session
      can :manage, Video
      can :manage, Recording
      can :manage, User
      can :manage, Guest
      can :stop_session, Room
      can :manage, SignupToken
      can :create, ::StripeDb::Coupon
      can :read, ::StripeDb::Coupon
      can :destroy, ::StripeDb::Coupon
      can :manage, ::Affiliate::Everflow::Transaction
      can :manage, ::Affiliate::Everflow::TrackedPayment
      can :read, ::Shop::AttachedList
      can :read, ::Shop::List
      can :read, ::Shop::ListsProduct
      can :read, ::Shop::Product
      can :read, ::Shop::ProductImage
      can :read, ::MarketingTools::OptInModal
      can :read, ::MarketingTools::OptInModalSubmit
      can :manage, WishlistItem
      can :manage, ::Blog::Post

      if user.superadmin?
        can :read, ActiveAdmin::Page, name: 'Config'
        can :update, ActiveAdmin::Page, name: 'Config'
        can :manage, Admin
        can :manage, LayoutCustomCode
        can :manage, SystemParameter
        can :manage, SystemUser
      end

      if user.morphx_admin? || user.superadmin?
        can :reindex, ActiveAdmin::Page, name: 'Dashboard'
        can :update_comments_count, ActiveAdmin::Page, name: 'Dashboard'
        can :clear_cache, ActiveAdmin::Page, name: 'Dashboard'

        can :read, ActiveAdmin::Page, name: 'Log::UserEvent'
        can :update, ActiveAdmin::Page, name: 'Log::UserEvent'

        can :read, ActiveAdmin::Page, name: 'Affiliate Tracking'
        can :generate_report, ActiveAdmin::Page, name: 'Affiliate Tracking'

        can :read, ActiveAdmin::Page, name: 'Basic Auth'
        can :generate, ActiveAdmin::Page, name: 'Basic Auth'

        can :read, ActiveAdmin::Page, name: 'Mailing'
        can :send_bulk, ActiveAdmin::Page, name: 'Mailing'
        can :read, ActiveAdmin::Page, name: 'System Reports'
        can :untracked_vod_report, ActiveAdmin::Page, name: 'System Reports'

        can :read, ActiveAdmin::Page, name: 'Webrtcservice::ChatBan'
        can :read, ActiveAdmin::Page, name: 'Webrtcservice::ChatChannel'
        can :read, ActiveAdmin::Page, name: 'Webrtcservice::ChatMember'

        can :read, ActiveAdmin::Page, name: 'Ffmpegservice Status'
        can :stop_stream, ActiveAdmin::Page, name: 'Ffmpegservice Status'
        can :reset_stream, ActiveAdmin::Page, name: 'Ffmpegservice Status'
        can :start_stream, ActiveAdmin::Page, name: 'Ffmpegservice Status'

        # Access Management
        can :manage, ::AccessManagement::Category
        can :manage, ::AccessManagement::Credential
        can :manage, ::AccessManagement::Group
        can :manage, ::AccessManagement::GroupsCredential
        can :manage, ::AccessManagement::GroupsMember
        can :manage, ::AccessManagement::GroupsMembersChannel
        can :manage, ::AccessManagement::Type

        # Blog
        can :manage, ::Blog::Comment
        can :manage, ::Blog::PostCover

        # IM
        can :manage, ::Im::Message
        can :manage, ::Im::Conversation
        can :manage, ::Im::ConversationParticipant

        # Service Subscription
        can :manage, CompanyFeatureParameter
        can :manage, FeatureHistoryUsage
        can :manage, FeatureParameter
        can :manage, FeatureUsage
        can :manage, PlanFeature
        can :manage, PlanPackage
        can :manage, ::StripeDb::ServicePlan
        can :manage, ::StripeDb::ServiceSubscription

        # Stripe
        can :manage, ::StripeDb::Plan
        can :manage, ::StripeDb::ConnectAccount
        can :manage, ::StripeDb::ConnectBankAccount
        can :manage, ::StripeDb::Subscription
        can :manage, Subscription
        can :manage, ::FreeSubscription
        can :manage, ::FreePlan
        can :manage, ::Partner::Plan
        can :manage, ::Partner::Subscription

        can :manage, AbstractSessionCancelReason
        can :manage, ::ActiveAdmin::Comment
        can :manage, ::ActiveStorage::Attachment
        can :manage, ::ActiveStorage::Blob
        can :manage, AdminLog
        can :manage, BanReason
        can :manage, BraintreeTransaction
        can :manage, ChannelCategory
        can :manage, ChannelImage
        can :manage, ChannelInvitedPresentership
        can :manage, ChannelType
        can :manage, Comment
        can :manage, CompanySetting
        can :manage, Contact
        can :manage, Discount
        can :manage, DiscountUsage
        can :manage, FoundUsMethod
        can :manage, ::FriendlyId::Slug
        can :manage, Identity
        can :manage, Industry
        can :manage, InteractiveAccessToken
        can :manage, IssuedSystemCredit
        can :manage, LinkPreview
        can :manage, ::Shop::AttachedList
        can :manage, ::Shop::List
        can :manage, ::Shop::ListsProduct
        can :manage, ::Shop::Product
        can :manage, ::Shop::ProductImage
        can :manage, Livestreamer
        can :manage, LogTransaction
        can :manage, MerchantCategory
        can :manage, OrganizationCover
        can :manage, OrganizationLogo
        can :manage, OrganizationMembership
        can :manage, Participant
        can :manage, ::Partner
        can :manage, PaymentTransaction
        can :manage, Payout
        can :manage, PayoutIdentity
        can :manage, PayoutMethod
        can :manage, PgSearchDocument
        can :manage, ::Plutus::Account
        can :manage, ::Plutus::CreditAmount
        can :manage, ::Plutus::DebitAmount
        can :manage, ::Plutus::Entry
        can :manage, Presenter
        can :manage, Rate
        can :manage, RecordedMember
        can :manage, RecordingMember
        can :manage, Recording
        can :manage, RecordingImage
        can :manage, Referral
        can :manage, ReferralCode
        can :manage, Review
        can :manage, Room
        can :manage, RoomMember
        can :manage, SessionParticipation
        can :manage, ::Shortener::ShortenedUrl
        can :manage, SocialLink
        can :manage, StreamPreview
        can :manage, Subscription
        can :view, SystemParameter
        can :manage, SystemTheme
        can :manage, SystemThemeVariable
        can :manage, TranscoderUptime
        can :manage, TranscoderUptime
        can :manage, WebrtcserviceRoom
        can :refresh_slug, User
        can :sign_in_as_presenter, User
        can :switch_transcode, User
        can :confirm_email, User
        can :recreate_short_url, User
        can :manage, UserAccount
        can :manage, UserImage
        can :manage, Video
        can :manage, VideoImage
        can :manage, View
        can :manage, FfmpegserviceAccount
        can :manage, ZoomMeeting
        can :manage, TranscodeTask

        # PageBuilder
        can :manage, ::PageBuilder::SystemTemplate
        can :manage, ::PageBuilder::HomeBanner

        # MOPS
        can :manage, ::MarketingTools::OptInModal
        can :manage, ::MarketingTools::OptInModalSubmit

        # Usage
        can :read, ActiveAdmin::Page, name: 'Usage::Event::Group'
        can :read, ActiveAdmin::Page, name: 'Usage::Event::GroupUser'
        can :manage, Storage::Record
      end
    end
  end
end
