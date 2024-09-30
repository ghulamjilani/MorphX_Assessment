# frozen_string_literal: true

ActiveAdmin.register ChannelType do
  menu parent: 'Admin settings'

  actions :all, except: [:destroy]
  form do |f|
    f.inputs do
      f.input :description
    end
    f.actions
  end

  controller do
    def permitted_params
      params.permit!
    end
  end
end
