module Cathode
  class Debug
    class << self
      def info
        output = ''
        Cathode::Base.versions.each do |version_number, version|
          output += "Version #{version_number}"

          version.resources.each do |resource_name, resource|
            output += "\n\t#{resource_name}"
          end
        end

        output
      end
    end
  end
end
