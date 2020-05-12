# frozen_string_literal: true

module Lbaas
  # openstak healthmonitor
  class Healthmonitor < Core::ServiceLayer::Model
    TYPES = %w[TCP PING HTTP HTTPS].freeze
    METHODS = %w[GET HEAD POST].freeze

    validates :type, presence: true
    validates :delay, presence: true, numericality: { greater_than: 0 }
    validates :max_retries, presence: true, inclusion: {
      in: '1'..'10',
      message: 'You can have between 1 and 10 retries'
    }
    validate :timeoutvalue

    def timeoutvalue
      new_timeout = read('timeout_value')
      if new_timeout.to_i <= 0
        errors.add(:timeout_value, 'Please enter a timeout greater 0')
      elsif new_timeout.to_i >= delay.to_i
        errors.add(:timeout_value, 'Please enter a timeout less than the "Delays" value')
      end
    end

    def http_type?
      return true if type && type.start_with?('HTTP')

      false
    end

    def timeout_value
      read('timeout')
    end

    def attributes_for_create
      {
        'name' => read('name'),
        'admin_state_up' => read('admin_state_up'),
        'delay' => read('delay'),
        'expected_codes' => read('expected_codes'),
        'http_method' => read('http_method'),
        'max_retries' => read('max_retries'),
        'pool_id' => read('pool_id'),
        'project_id' => read('project_id'),
        'project_id' => read('project_id'),
        'timeout' => read('timeout_value'),
        'type' => read('type'),
        'url_path' => read('url_path')
      }.delete_if { |_k, v| v.blank? }
    end

    def attributes_for_update
      {
        'name' => read('name'),
        'admin_state_up' => read('admin_state_up'),
        'delay' => read('delay'),
        'expected_codes' => read('expected_codes'),
        'http_method' => read('http_method'),
        'max_retries' => read('max_retries'),
        'timeout' => read('timeout_value'),
        'url_path' => read('url_path')
      }.delete_if { |k, v| v.blank? && !%w[name].include?(k) }
    end
  end
end
