module Cathode
  # Provides information about the Cathode API.
  class Debug
    class << self
      # Gathers information about the API's versions, properties, resources, and
      # actions.
      # @return [String] A string listing the versions, resources, and actions
      def info
        output = ''
        Cathode::Base.versions.each do |version|
          output += "\nVersion #{version.version}"

          version._resources.each do |resource|
            output += "\n  #{resource.name}/"
            resource.actions.each do |action|
              output += "\n    #{action.name}"
            end
          end
        end

        output
      end
    end
  end
end
