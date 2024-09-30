# frozen_string_literal: true

module Api
  module V1
    module User
      module AccessManagement
        class GroupsController < Api::V1::User::AccessManagement::ApplicationController
          def index
            @groups = ::AccessManagement::Group.includes(:groups_credentials, credentials: %i[category type])
                                               .for_organization(current_user.current_organization)
                                               .where(deleted: false)
                                               .order(system: :desc, name: :asc)
            @count = @groups.count
          end

          def show
            @group = ::AccessManagement::Group.for_organization(current_user.current_organization).find(params[:id])
            render :show
          end

          def create
            authorize!(:manage_roles, current_user.current_organization)
            @group = current_user.current_organization.groups.create!(group_params)
            @group.credential_ids = params[:group][:credential_ids] if params[:group].key?(:credential_ids)
            render :show
          end

          def update
            authorize!(:manage_roles, current_user.current_organization)
            @group = current_user.current_organization.groups.find(params[:id])
            @group.update(group_params)
            @status = @group.errors.any? ? 422 : 200
            if params[:group].key?(:credential_ids)
              credential_ids = valid_credential_ids(params[:group][:credential_ids])
              if credential_ids.count < params[:group][:credential_ids].count
                return render_json(422, I18n.t('controllers.api.v1.user.access_management.groups.errors.add_credential_error'))
              end

              @group.credential_ids = credential_ids
            end
            render :show, status: @status
          end

          def destroy
            authorize!(:manage_roles, current_user.current_organization)
            @group = current_user.current_organization.groups.find(params[:id])
            @group.update(deleted: true)
            head :ok
          end

          private

          def group_params
            params.require(:group).permit(:name, :description, :enabled, :color)
          end

          def valid_credential_ids(credential_ids)
            credentials = ::AccessManagement::Credential.active.where(id: credential_ids)

            credentials.select { |credential| current_ability.can?(:add_credential, @group, credential) }.map(&:id)
          end
        end
      end
    end
  end
end
