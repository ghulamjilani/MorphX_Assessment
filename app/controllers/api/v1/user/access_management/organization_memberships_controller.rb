# frozen_string_literal: true

module Api
  module V1
    module User
      module AccessManagement
        class OrganizationMembershipsController < Api::V1::User::AccessManagement::ApplicationController
          before_action :set_organization
          before_action :set_organization_membership, only: %i[show update destroy]

          def index
            query = @organization.organization_memberships_participants.includes(:user, groups: [:credentials], groups_members_channels: :channel)
            q = params[:q]
            if q.present?
              query = query.joins(:user).where('users.display_name ILIKE ? OR users.email LIKE ?', "%#{q}%", "%#{q.downcase}%")
            end

            @count = query.count

            order_by = %w[id created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'id'
            order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'
            @organization_memberships = query.order(Arel.sql("organization_memberships.#{order_by} #{order}")).limit(@limit).offset(@offset)
          end

          def show
          end

          def create
            authorize!(:invite_members, @organization)
            @organization_membership = @organization.organization_memberships.new
            group_ids = params[:groups].to_a.map { |group| group['group_id'].to_i }
            # enterprise user always has member
            group_ids << ::AccessManagement::Group.where.not(id: group_ids).find_by(code: :member, enabled: true)&.id
            group_ids = group_ids.uniq.compact
            validated_group_ids = valid_group_ids(group_ids)
            if validated_group_ids.empty?
              return render_json(422, I18n.t('controllers.api.v1.user.access_management.organization_memberships.errors.invite_error'))
            elsif validated_group_ids.count < group_ids.count
              return render_json(422, I18n.t('controllers.api.v1.user.access_management.organization_memberships.errors.members_limit_error'))
            end

            invited_user = if params[:email].present?
                             # user comes from search tab
                             ::User.find_by(email: params[:email])
                           elsif params[:user_id].present?
                             # user comes from invite by email tab
                             ::User.find_by(id: params[:user_id])
                           end

            if invited_user.blank?
              return render_json(422, "Email can't be blank") if params[:email].blank?

              invited_user = ::User.invite!(
                { email: params[:email], first_name: params[:first_name], last_name: params[:last_name] }, current_user
              ) do |u|
                u.before_create_generic_callbacks_and_skip_validation
                u.skip_invitation = true
              end
            end
            @organization_membership = @organization.organization_memberships.find_or_create_by(user_id: invited_user.id)
            status = Rails.application.credentials.global[:enterprise] ? ::OrganizationMembership::Statuses::ACTIVE : ::OrganizationMembership::Statuses::PENDING

            @organization_membership.update(membership_type: :participant, status: status)

            if @organization_membership.errors.any?
              @status = 422
              return render :show, status: @status
            end

            @organization_membership.group_ids = validated_group_ids

            params[:groups].to_a.each do |group|
              group_member = @organization_membership.groups_members.find_by(access_management_group_id: group['group_id'])
              next unless group_member

              channels = @organization.channels.where(id: group['channel_ids'].to_a)
              group_member.channels << channels unless channels.empty?
            end

            invited_user.create_presenter if invited_user.presenter.blank?

            render :show
          end

          def update
            authorize!(:invite_members, @organization)
            authorize!(:edit_roles, @organization_membership)
            group_ids = valid_group_ids(params[:group_ids])

            if group_ids.empty?
              return render json: { message: I18n.t('controllers.api.v1.user.access_management.organization_memberships.errors.update_error') }, status: 422
            elsif group_ids.count < params[:group_ids].count
              return render_json(422, I18n.t('controllers.api.v1.user.access_management.organization_memberships.errors.members_limit_error'))
            end

            @organization_membership.group_ids = group_ids
            @organization.touch # need to reset cache when group was removed
            render :show
          end

          def destroy
            authorize!(:remove_members, @organization)
            authorize!(:edit_roles, @organization_membership)
            @organization_membership.destroy
            head :ok
          end

          def import_from_csv
            authorize!(:invite_members, @organization)
            if params[:file].present?
              delimiter = ::CsvDelimiter.find(params[:file].path)
              csv_file = CSV.parse(File.read(params[:file].path), headers: true, col_sep: delimiter)
              headers = csv_file.headers
              email_key = headers.detect { |key_name| /email/i.match(key_name) }
              first_name_key = headers.detect { |key_name| /first name/i.match(key_name) }
              last_name_key = headers.detect { |key_name| /last name/i.match(key_name) }
              gender_key = headers.detect { |key_name| /gender/i.match(key_name) }
              birthday_key = headers.detect { |key_name| /birthday/i.match(key_name) }
              delete_key = headers.detect { |key_name| /delete/i.match(key_name) }

              return render_json(422, I18n.t('controllers.free_subscriptions_controller.errors.invalid_file')) if email_key.blank?

              groups = begin
                JSON.parse(params[:groups])
              rescue StandardError
                []
              end

              csv_file.each do |row|
                attrs = row.to_h
                next if attrs[email_key].blank?

                job_params = {
                  first_name: attrs[first_name_key],
                  last_name: attrs[last_name_key],
                  email: attrs[email_key],
                  gender: attrs[gender_key],
                  birthday: attrs[birthday_key],
                  delete: attrs[delete_key],
                  group_ids: groups,
                  organization_id: @organization.id,
                  user_id: current_user.id
                }
                OrganizationMembershipJobs::Create.perform_async(job_params)
              end
            end
            head :ok
          end

          private

          def set_organization
            @organization = ::Organization.joins(%(LEFT JOIN organization_memberships ON organization_memberships.organization_id = organizations.id))
                                          .where('organizations.user_id = :id OR organization_memberships.user_id = :id AND organization_memberships.status = :status_active', id: current_user.id, status_active: ::OrganizationMembership::Statuses::ACTIVE).find(params[:organization_id])
          end

          def set_organization_membership
            @organization_membership = @organization.organization_memberships_participants.find(params[:id])
          end

          def valid_group_ids(ids)
            groups = ::AccessManagement::Group.for_organization(current_user.current_organization).where(
              deleted: false, id: ids
            )
            # Validate group add permissions

            groups.select { |group| current_ability.can?(:add_role, group, @organization_membership) }.map(&:id)
          end
        end
      end
    end
  end
end
