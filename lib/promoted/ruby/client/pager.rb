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
            def validate_paging(insertions, retrieval_insertion_offset, paging)
              if paging && paging[:offset]
                offset = [0, paging[:offset]].max
                if offset >= insertions.length
                  raise InvalidPagingError.new("Invalid page offset (insertion size #{insertions.length}, offset #{offset})", [])
                end
                if offset < retrieval_insertion_offset
                  raise InvalidPagingError.new("Invalid page offset (retrieval_insertion_offset #{retrieval_insertion_offset}, offset #{offset})", [])
                end
              end
            end

            def apply_paging(insertions, retrieval_insertion_offset, paging = nil)
              begin
                validate_paging(insertions, retrieval_insertion_offset, paging)
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
              retrieval_insertion_offset = [0, retrieval_insertion_offset].max
              index = [0, offset - retrieval_insertion_offset].max

              size = paging[:size]
              if size <= 0
                size = insertions.length
              end

              final_insertion_size = [size, insertions.length - index].min
              insertion_page = Array.new(final_insertion_size)
              0.upto(final_insertion_size - 1) {|i|
                request_insertion = insertions[index]
                # Pager returns response insertions.  Create a copy and fill in some of the fields.
                response_insertion = Hash[]
                response_insertion[:content_id] = request_insertion[:content_id]
                response_insertion[:insertion_id] = request_insertion[:insertion_id]
                # TODO - implement retrieval_start.
                response_insertion[:position] = offset
                insertion_page[i] = response_insertion
                index = index + 1
                offset = offset + 1
              }

              return insertion_page
            end
        end
      end
    end
end
