module ActiveRecord
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

