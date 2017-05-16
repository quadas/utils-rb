# Audit data modifications for AR model
#
# ==== Example
#   class Foo < ActiveRecord::Base
#     include Utils::AR::Auditable
#     audit :name, :position
#
#     # audit all columns, created_at and updated_at auto excluded
#     audit :all
#     audit all: { exclude: [:id, :age] }
#   end
require 'active_support/concern'
require 'active_support/core_ext/object/blank'

module Utils
  module AR
    module Auditable
      extend ActiveSupport::Concern

      included do
        has_many :activities, as: :auditable

        class_attribute :audit_columns
        self.audit_columns = Set.new

        after_create :write_activity_when_create, if: -> { audit_columns.present? }
        after_update :write_activity_when_update, if: -> { audit_columns.present? }
      end

      def write_activity_when_create
        write_activity('create')
      end

      def write_activity_when_update
        write_activity('update')
      end

      def write_activity(action)
        changed_content = changes.slice(*audit_columns)

        changed_content.each do |column, difference|
          if difference.any? { |value| value.is_a? BigDecimal }
            changed_content[column] = difference.map(&:to_s)
          end
        end

        changed_content.present? && activities.create(
          operator_id: User.current_user&.id,
          action: action,
          content: changed_content
        )
      end

      module ClassMethods
        def audit(*args)
          options = args.dup.extract_options!
          exclude_columns = options.fetch(:all, {}).fetch(:exclude, [])
          self.audit_columns = if [:all] == args
                                 column_names - %w(created_at updated_at)
                               elsif exclude_columns.present?
                                 column_names - %w(created_at updated_at) - exclude_columns.map(&:to_s)
                               else
                                 args.map(&:to_s) & column_names
                               end
        end
      end
    end
  end
end
