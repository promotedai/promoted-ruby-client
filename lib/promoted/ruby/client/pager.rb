module Promoted
    module Ruby
      module Client
        class Pager
            def apply_paging (insertions, insertion_page_type, paging = nil)
              if !paging
                paging = {
                  :offset => 0,
                  :size => insertions.length
                }
              end

              offset = [0, paging[:offset]].max

              # This is invalid input, stop it before it goes to the server.
              if offset >= insertions.length
                return []
              end

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