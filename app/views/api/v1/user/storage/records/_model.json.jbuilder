# frozen_string_literal: true

json.id                     model.id
json.title                  model.try(:always_present_title) || model.try(:title)
json.relative_path          model.try(:relative_path)
