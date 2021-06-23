module Promoted
  module Ruby
    module Client
      USE_CASES = {'UNKNOWN_USE_CASE'=> 'UNKNOWN_USE_CASE',
                   'CUSTOM'=> 'CUSTOM',
                   'SEARCH'=> 'SEARCH',
                   'SEARCH_SUGGESTIONS'=> 'SEARCH_SUGGESTIONS',
                   'FEED'=> 'FEED',
                   'RELATED_CONTENT'=> 'RELATED_CONTENT',
                   'CLOSE_UP'=> 'CLOSE_UP',
                   'CATEGORY_CONTENT'=> 'CATEGORY_CONTENT',
                   'MY_CONTENT'=> 'MY_CONTENT',
                   'MY_SAVED_CONTENT'=> 'MY_SAVED_CONTENT',
                   'SELLER_CONTENT'=> 'SELLER_CONTENT',
                   'DISCOVER'=> 'DISCOVER'}

      INSERTION_PAGING_TYPE = {'UNPAGED' => 'UNPAGED',
                               'PRE_PAGED' => 'PRE_PAGED'}

      COHORT_ARM = {'UNKNOWN_GROUP' => 'UNKNOWN_GROUP',
                    'CONTROL' => 'CONTROL',
                    'TREATMENT' => 'TREATMENT',
                    'TREATMENT1' => 'TREATMENT1',
                    'TREATMENT2' => 'TREATMENT2',
                    'TREATMENT3' => 'TREATMENT3'}
    end
  end
end
