#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Storages::ProjectStoragesController < ApplicationController
  using Storages::Peripherals::ServiceResultRefinements

  menu_item :overview
  model_object Storages::ProjectStorage

  before_action :require_login
  before_action :find_model_object
  before_action :find_project_by_project_id
  before_action :render_403, unless: -> { User.current.allowed_in_project?(:view_file_links, @project) }

  def open
    storage_open_url = @object.open(current_user).match(
      on_success: ->(url) { url },
      on_failure: ->(error) { raise_error(error) }
    )
    if @object.project_folder_automatic?
      storage = @object.storage
      # check if user "see" project_folder
      ::Storages::Peripherals::Registry
        .resolve("queries.#{storage.short_provider_type}.file_info")
        .call(storage:,
              user: current_user,
              file_id: @object.project_folder_id)
        .match(
          on_success: user_can_read_project_folder(storage_open_url:),
          on_failure: user_can_not_read_project_folder(storage:, storage_open_url:)
        )
    else
      redirect_to storage_open_url
    end
  end

  private

  def user_can_read_project_folder(storage_open_url:)
    ->(_) do
      respond_to do |format|
        format.turbo_stream do
          render(
            turbo_stream: OpTurbo::StreamComponent.new(
              action: :update,
              target: Storages::OpenProjectStorageModalComponent.dialog_body_id,
              template: Storages::OpenProjectStorageModalComponent::Body.new(:success).render_in(view_context)
            ).render_in(view_context)
          )
        end
        format.html { redirect_to storage_open_url }
      end
    end
  end

  def user_can_not_read_project_folder(storage_open_url:, storage:)
    ->(result) do
      respond_to do |format|
        format.turbo_stream { head :no_content }
        format.html do
          case result.code
          when :unauthorized
            redirect_to(
              oauth_clients_ensure_connection_url(
                oauth_client_id: storage.oauth_client.client_id,
                storage_id: storage.id,
                destination_url: request.url
              )
            )
          when :forbidden
            redirect_to(
              project_overview_path(project_id: @project.identifier),
              flash: {
                modal: {
                  type: 'Storages::OpenProjectStorageModalComponent',
                  parameters: {
                    project_storage_open_url: request.path,
                    redirect_url: storage_open_url,
                    state: :waiting
                  }
                }
              }
            )
          end
        end
      end
    end
  end
end
