require 'spec_helper'

describe RestPack::Serializer::SideLoading do
  context "when side-loading" do
    let(:side_loads) { MyApp::ArtistSerializer.side_loads(models, options) }

    describe ".has_many" do

      before(:each) do
        @artist1 = FactoryGirl.create(:artist_with_albums, album_count: 2)
        @artist2 = FactoryGirl.create(:artist_with_albums, album_count: 1)
      end

      context "with a single model" do
        let(:models) { [@artist1] }

        context "when including :albums" do
          let(:options) { RestPack::Serializer::Options.new(MyApp::ArtistSerializer, { "include" => "albums" }) }

          it "returns side-loaded albums" do
            side_loads[:albums].count.should == @artist1.albums.count
            side_loads[:meta][:albums][:page].should == 1
            side_loads[:meta][:albums][:count].should == @artist1.albums.count
          end
        end
      end

      context "with two models" do
        let(:models) { [@artist1, @artist2] }

        context "when including :albums" do
          let(:options) { RestPack::Serializer::Options.new(MyApp::ArtistSerializer, { "include" => "albums" }) }

          it "returns side-loaded albums" do
            expected_count = @artist1.albums.count + @artist2.albums.count
            side_loads[:albums].count.should == expected_count
            side_loads[:meta][:albums][:count].should == expected_count
          end
        end
      end

      context 'with a model renaming an association' do
        let(:models){ [@artist1] }
        let(:options) { RestPack::Serializer::Options.new(MyApp::ArtistSerializer, { "include" => "records" }) }

        it 'should return side-loaded records' do
          side_loads[:records].count.should == @artist1.albums.count
          side_loads[:meta][:records][:page].should == 1
          side_loads[:meta][:records][:count].should == @artist1.albums.count
        end
      end
    end

    # Disable the has_many sideload tests as it has postgresql specific
    # distinct on clause, thus this gem/lib would need to test via
    # postgres db not sqllite.
    #
    # describe '.has_many through' do
    #   context 'when including :fans' do
    #     let(:options) { RestPack::Serializer::Options.new(MyApp::ArtistSerializer, { "include" => "fans" }) }
    #     let(:artist_1) {FactoryGirl.create :artist_with_fans}
    #     let(:artist_2) {FactoryGirl.create :artist_with_fans}

    #     context "with a single model" do
    #       let(:models) {[artist_1]}

    #       it 'returns side-loaded fans' do
    #         side_loads[:fans].count.should == artist_1.fans.count
    #         side_loads[:meta][:fans][:page].should == 1
    #         side_loads[:meta][:fans][:count].should == artist_1.fans.count
    #       end
    #     end
    #     context "with a multiple models" do
    #       let(:models) {[artist_1, artist_2]}

    #       it 'returns side-loaded fans' do
    #         expected_count = artist_1.fans.count  + artist_2.fans.count

    #         side_loads[:fans].count.should == expected_count
    #         side_loads[:meta][:fans][:page].should == 1
    #         side_loads[:meta][:fans][:count].should == expected_count
    #       end

    #       context "when there are shared fans" do
    #         before do
    #           artist_1.fans << artist_2.fans.first
    #         end
    #         it "should not include duplicates in the linked resource collection" do
    #           expected_count = (artist_1.fans + artist_2.fans).uniq.count
    #           expect(side_loads[:fans].count).to eq(expected_count)
    #           expect(side_loads[:meta][:fans][:count]).to eq(expected_count)
    #         end
    #       end
    #     end
    #   end
    # end
  end
end
