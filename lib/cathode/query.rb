module Cathode
  # Holds the Cathode Query DSL interface.
  class Query
    attr_reader :results

    # Initialize and parse a query.
    # @param model [Class] A subclass of `ActiveRecord::Base`.
    # @param query [String] The query to be executed
    def initialize(model, query)
      clauses = query.split ','
      results = model
      clauses.each do |clause|
        words = clause.split
        results = case words.first
                  when 'where'
                    results.where(words.drop(1).join ' ')
                  else
                    results.where(words.join ' ')
                  end
      end
      @results = results
    end
  end
end
