# frozen_string_literal: true

require 'time'

module Calendly
  # Calendly model utility.
  module ModelUtils
    # @param [Hash] attrs the attributes of the model.
    # @param [Calendly::Client] the api client.
    def initialize(attrs = nil, client = nil)
      @client = client
      set_attributes attrs
    end

    #
    # Returns api client.
    #
    # @return [Calendly::Client]
    # @raise [Calendly::Error] if the client is nil.
    # @since 0.1.0
    def client
      raise Error, '@client is not ready.' if !@client || !@client.is_a?(Client)

      @client
    end

    #
    # alias of uuid.
    #
    # @return [String]
    # @raise [Calendly::Error] if uuid is not defined.
    # @since 0.1.0
    def id
      raise Error, 'uuid is not defined.' unless defined? uuid

      uuid
    end

    def inspect
      description = "uuid:#{uuid}" if respond_to? :uuid
      "\#<#{self.class}:#{object_id} #{description}>"
    end

    module ClassMethods
      def extract_uuid(str)
        return unless defined? self::UUID_RE
        return unless str
        return if str.empty?

        m = self::UUID_RE.match str
        return if m.nil?

        m[1]
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end

    private

    def set_attributes(attrs)
      return if attrs.nil?
      return unless attrs.is_a? Hash
      return if attrs.empty?

      attrs.each do |key, value|
        next unless respond_to? "#{key}=".to_sym

        if defined?(self.class::TIME_FIELDS) && self.class::TIME_FIELDS.include?(key)
          value = Time.parse value
        end
        instance_variable_set "@#{key}", value
      end
      after_set_attributes(attrs)
    end

    def after_set_attributes(attrs)
      @uuid = self.class.extract_uuid(attrs[:uri]) if respond_to? :uuid=
    end

    #
    # Get all collection from single page or plurality of pages.
    #
    # @param [Proc] request_proc the procedure of request portion of collection.
    # @param [Hash] opts the optional request parameters for the procedure.
    # @return [Array<Calendly::Model>]
    # @since 0.1.0
    def auto_pagination(request_proc, opts)
      items = []
      loop do
        new_items, next_opts = request_proc.call opts
        items = [*items, *new_items]
        break unless next_opts

        opts = next_opts
      end
      items
    end
  end
end
