module Cathode
  class Debug
    class << self
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
