# frozen_string_literal: true

require 'spec_helper'

action_methods = %w[index show edit new destroy]
skip_classes = ['ServiceAdminPanel::ConfigController']
controllers = ActiveAdmin.application.namespaces[:service_admin_panel].resources.map(&:controller)
controllers_map = controllers.filter_map do |controller|
  next if skip_classes.include?(controller.to_s)

  am = controller.action_methods.to_a
  {
    class: controller,
    factory: "aa_stub_#{controller.to_s.gsub('Controller', '').demodulize.underscore}".to_sym,
    methods: (action_methods - (action_methods - am)).map(&:to_sym)
  }
end

controllers_map.each do |param|
  RSpec.describe param[:class], type: :controller do
    context "with factory #{param[:factory]}" do
      let!(:current_admin) { create(:admin, role: :superadmin) }
      let!(:factory_object) { create(param[:factory]) }
      # let (:factory_new_object){build(param[:factory])}

      before { sign_in current_admin, scope: 'admin' }

      describe 'GET index' do
        if param[:methods].include?(:index)
          it 'returns http success' do
            get :index
            expect(response).to have_http_status(:success)
          end
        else
          it 'returns http 404' do
            expect { get :index }.to raise_error(ActionController::UrlGenerationError)
          end
        end
      end

      describe 'GET new' do
        if param[:methods].include?(:new)
          it 'returns http success' do
            get :new
            expect(response).to have_http_status(:success)
          end
        else
          it 'returns http 404' do
            expect { get :new }.to raise_error(ActionController::UrlGenerationError)
          end
        end
      end

      describe 'GET edit' do
        if param[:methods].include?(:edit)
          it 'returns http success' do
            get :edit, params: { id: factory_object.id }
            expect(response).to have_http_status(:success)
          end
        else
          it 'returns http 404' do
            expect { get :edit, params: { id: factory_object.id } }.to raise_error(ActionController::UrlGenerationError)
          end
        end
      end

      describe 'GET show' do
        if param[:methods].include?(:show)
          it 'returns http success' do
            get :show, params: { id: factory_object.id }
            expect(response).to have_http_status(:success)
          end
        else
          it 'returns http 404' do
            expect { get :show, params: { id: factory_object.id } }.to raise_error(ActionController::UrlGenerationError)
          end
        end
      end

      # describe "POST create" do
      #   if param[:methods].include?(:create)
      #     it 'returns http success' do
      #       post :create, params: factory_new_object.attributes
      #       expect(response).to have_http_status(:success)
      #     end
      #   else
      #     it 'returns http 404' do
      #       expect(post: :create ).not_to be_routable
      #     end
      #   end
      # end
      #
      describe 'DELETE destroy' do
        if param[:methods].include?(:destroy)
          it 'returns http success' do
            delete :destroy, params: { id: factory_object.id }
            expect(response).to have_http_status(:found)
          end
        else
          it 'returns http 404' do
            expect do
              delete :destroy, params: { id: factory_object.id }
            end.to raise_error(ActionController::UrlGenerationError)
          end
        end
      end
    end
  end
end
