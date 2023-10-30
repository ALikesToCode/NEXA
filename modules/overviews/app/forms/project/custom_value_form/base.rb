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

class Project::CustomValueForm::Base < ApplicationForm
  def initialize(custom_field:, custom_field_value:, project:)
    @custom_field = custom_field
    @custom_field_value = custom_field_value
    @project = project
  end

  def base_config
    {
      name:,
      id:,
      scope_name_to_model: false,
      scope_id_to_model: false,
      placeholder: @custom_field.name,
      label: @custom_field.name,
      value: @custom_field_value.value,
      required: @custom_field.is_required?,
      invalid: @custom_field_value.errors.any?,
      validation_message: @custom_field_value.errors.any? ? @custom_field_value.errors.full_messages&.join(" ") : nil
    }
  end

  def name
    if @custom_field_value.new_record?
      "project[new_custom_field_values_attributes][#{@custom_field_value.custom_field_id}][value]"
    else
      "project[custom_field_values_attributes][#{@custom_field_value.id}][value]"
    end
  end

  def id
    name.gsub(/[\[\]]/, "_")
  end
end
