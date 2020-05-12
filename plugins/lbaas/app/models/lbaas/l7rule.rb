module Lbaas
  class L7rule < Core::ServiceLayer::Model
    TYPES          = %w[HOST_NAME PATH FILE_TYPE HEADER COOKIE].freeze
    COMPARE_TYPES  = %w[EQUAL_TO STARTS_WITH ENDS_WITH CONTAINS].freeze

    validates :key, presence: {
      message: 'Please set a key name for Cookie and Header types'
    }, if: :type_header_cookie?
    validates :key, format: {
      with: /\A[a-zA-Z!#$%&'*+-.^_`|~]+\z/,
      message: 'Invalid characters in value. See RFCs 2616, 2965, 6265, 7230.'
    }, if: :type_header_cookie?
    validates :value, presence: true, format: {
      with: %r{\A[a-zA-Z\d!#$%&'()*+-\./:<=>?@\[\]^_`{|}~]+\z},
      message: 'Invalid characters in value. See RFCs 2616, 2965, 6265.'
    }
    validates :type, presence: true
    validates :compare_type, presence: true

    attr_accessor :in_transition

    def rule_formula
      s = type + ' '
      s += 'NOT ' if invert
      s += compare_type + ' '
      s = s.humanize
      s += "KEY[#{key}]=" if key
      s += value
      s
    end

    def type_header_cookie?
      return type == 'HEADER' || type == 'COOKIE'
    end

    def in_transition?
      false
    end

    def attributes_for_create
      {
        'type' => read('type'),
        'compare_type' => read('compare_type'),
        'value' => read('value'),
        'project_id' => read('project_id'),
        'key' => read('key'),
        'invert' => read('invert')
      }.delete_if { |_k, v| v.blank? }
    end

    def attributes_for_update
      {
        'type' => read('type'),
        'compare_type' => read('compare_type'),
        'value' => read('value'),
        'key' => read('key'),
        'invert' => read('invert')
      }.delete_if { |k, v| v.blank? && !%w[value invert].include?(k) }
    end

    def perform_service_create(create_attributes)
      service.create_l7rule(l7policy_id, create_attributes)
    end

    def perform_service_update(id, update_attributes)
      service.update_l7rule(l7policy_id, id, update_attributes)
    end

    def perform_service_delete(id)
      service.delete_l7rule(l7policy_id, id)
    end
  end
end
