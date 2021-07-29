require 'spec_helper'

RSpec.describe Promoted::Ruby::Client::Util do

    context("translate array") do
        it "leaves an ordinary array alone" do
            arr = ["a", "b"]
            new_arr = described_class.translate_array(arr)
            expect(new_arr).to eq arr
        end

        it "translates top-level hashes to snaked symbols" do
            arr = [{"aA" => "b"}, {"cC" => "d"}]
            new_arr = described_class.translate_array(arr)
            expect(new_arr).to eq [{:a_a => "b"}, {:c_c => "d"}]
        end

        it "deals with things that are already symbols" do
            arr = [{:a_a => "b"}, {:c_c => "d"}]
            new_arr = described_class.translate_array(arr)
            expect(new_arr).to eq [{:a_a => "b"}, {:c_c => "d"}]
        end

        it "translates nested hashes to snaked symbols" do
            arr = [ {"zZ" => [{"aA" => "b"}, {"cC" => "d"}] } ]
            new_arr = described_class.translate_array(arr)
            expect(new_arr).to eq [{:z_z => [{:a_a => "b"}, {:c_c => "d"}] }]
        end
    end

    context("translate hash") do
        it "translates all kv types" do
            h = {
                "aA" => "b",
                "cC" => [ { "dD" => "e" } ],
                "fF" => {
                    "gG" => "h"
                }
            }

            new_h = described_class.translate_hash(h)

            result = {
                :a_a => "b",
                :c_c => [ { :d_d => "e" } ],
                :f_f => {
                    :g_g => "h"
                }
            }

            expect(new_h).to eq result
        end
    end
end
