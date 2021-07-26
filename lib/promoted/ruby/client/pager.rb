module Promoted
    module Ruby
      module Client
        class InvalidPagingError < StandardError
          attr_reader :default_insertions_page

          def initialize(message, default_insertions_page)
            super(message)
            @default_insertions_page = default_insertions_page
          end
        end
        
        class Pager
            def validate_paging (insertions, paging)
              if paging && paging[:offset] && paging[:offset] >= insertions.length
                raise InvalidPagingError.new("Invalid page offset (insertion size #{insertions.length}, offset #{paging[:offset]})", [])
              end
            end

            def apply_paging (insertions, insertion_page_type, paging = nil)
              begin
                validate_paging(insertions, paging)
              rescue InvalidPagingError => err
                # This is invalid input, stop it before it goes to the server.
                return err.default_insertions_page
              end

              if !paging
                paging = {
                  :offset => 0,
                  :size => insertions.length
                }
              end

              offset = [0, paging[:offset]].max

              index = offset
              if insertion_page_type == Promoted::Ruby::Client::INSERTION_PAGING_TYPE['PRE_PAGED']
                # When insertions are pre-paged, we don't use offset to
                # window into the provided insertions, although we do use it when
                # assigning positions.
                index = 0
              end

              size = paging[:size]
              if size <= 0
                size = insertions.length
              end

              final_insertion_size = [size, insertions.length].min
              insertion_page = Array.new(final_insertion_size)
              0.upto(final_insertion_size - 1) {|i|
                insertion = insertions[index]
                if insertion[:position] == nil
                  insertion[:position] = offset
                end
                insertion_page[i] = insertion
                index = index + 1
                offset = offset + 1
              }

              return insertion_page
            end
        end
      end
   end
end
