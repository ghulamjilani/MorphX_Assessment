# frozen_string_literal: true

ActiveAdmin.register Plutus::Account do
  menu parent: 'Ledger'
  config.batch_actions = false

  before_action :skip_sidebar!, only: :index

  actions :all, except: %i[new edit destroy]

  index download_links: false do
    render partial: 'index'
  end

  show do
    render partial: 'show'
  end

  controller do
    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
