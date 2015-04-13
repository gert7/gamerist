module ActiveRecord
  module AttributeMethods
    module TimeZoneConversion
      class TimeZoneConverter
        module ClassMethods
          private
          def create_time_zone_conversion_attribute?(name, cast_type)
            time_zone_aware_attributes &&
              !self.skip_time_zone_conversion_for_attributes.include?(name.to_sym) &&
              (:datetime == cast_type.to_sym)
          end
        end
      end
    end
  end
  class Base
    def self.reset_subclasses #:nodoc:
      @@subclasses = {}
      subclasses.each do |subclass|
        next unless ActiveSupport::Dependencies.autoloaded?(subclass)
        (@@subclasses[subclass.superclass] ||= []) << subclass
      end
    end
  end
end

