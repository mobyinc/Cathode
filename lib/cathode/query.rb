module Cathode
  class Query
    attr_reader :results

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
