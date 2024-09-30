# frozen_string_literal: true

# REMOVEME after firebase deploy or 30.04.2019
# curl -XPOST --insecure \
#     --header "Content-Type: application/json" \
#     --data '
#         {
#             "message":{
#                 "topic":"weat3her",
#                 "notification": {
#                     "title":"Check out this sale!",
#                     "body":"All items half off through Friday"
#                 },
#                 "android":{
#                     "notification": {
#                         "click_action":"OPEN_ACTIVITY_3"
#                     }
#                 },
#                 "apns": {
#                     "payload": {
#                         "aps": {
#                             "category": "SALE_CATEGORY"
#                         }
#                     }
#                 }
#             }
#         }
#     ' \
#   https://qa-portal.unite.live/api_portal/system/firebase
class Api::System::FirebaseController < Api::System::ApplicationController
  def create
    raise 'disable for prod' if Rails.env.production?

    render plain: Sender::FirebaseLib.send(message: params[:message], sync: true)
  rescue StandardError => e
    render plain: e.message
  end
end
