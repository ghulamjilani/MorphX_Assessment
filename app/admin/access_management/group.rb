# frozen_string_literal: true

ActiveAdmin.register AccessManagement::Group do
  menu parent: 'Access Management'

  actions :all

  filter :name
  filter :code
  filter :description
  filter :system
  filter :enabled
  filter :deleted
  filter :organization_id, label: 'Organization ID'
  filter :organization_name_cont, label: 'Organization name'

  batch_action :enable do |ids|
    models = AccessManagement::Group.where(id: ids)
    models.update_all(enabled: true)

    redirect_to collection_path, alert: 'Roles enabled!'
  end

  batch_action :disable do |ids|
    models = AccessManagement::Group.where(id: ids)
    models.update_all(enabled: false)

    redirect_to collection_path, alert: 'Roles disabled!'
  end
  show do
    columns do
      column do
        panel 'Role' do
          attributes_table_for resource do
            row :id
            row :code
            row :name
            row :description
            row :organization
            row :deleted
            row :enabled
            row :system
          end
        end
      end
      column do
        panel 'Credentials' do
          table_for resource.groups_credentials.includes(:credential) do
            column 'Name' do |obj|
              obj.credential.name
            end
            column 'Code' do |obj|
              obj.credential.code
            end
            column 'Is For Channel' do |obj|
              obj.credential.is_for_channel
            end
            column 'Is Master Only' do |obj|
              obj.credential.is_master_only
            end
            column 'Type' do |obj|
              obj.credential.type.name
            end
            column 'Actions' do |obj|
              link_to 'Delete', service_admin_panel_access_management_groups_credential_path(obj), method: :delete
            end
          end
        end
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :code
      f.input :name
      f.input :description
      f.input :organization, as: :select, collection: Organization.order(name: :asc)
      f.input :enabled
      f.input :system
      f.input :deleted
    end
    f.inputs do
      AccessManagement::Category.find_each do |category|
        f.input :credentials, as: :check_boxes, label: category.name,
                              collection: AccessManagement::Credential.where(category: category)
      end
    end
    f.actions
  end
  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
