require 'spec_helper'

describe Note do
  let(:project) { Factory :project }
  let!(:commit) { project.commit }

  describe "Associations" do
    it { should belong_to(:project) }
  end

  describe "Validation" do
    it { should validate_presence_of(:note) }
    it { should validate_presence_of(:project) }
  end

  it { Factory.create(:note,
                      :project => project).should be_valid }
  describe "Scopes" do
    it "should have a today named scope that returns ..." do
      Note.today.where_values.should == ["created_at >= '#{Date.today}'"]
    end
  end
 
  describe "Commit notes" do 

    before do 
      @note = Factory :note,
        :project => project,
        :noteable_id => commit.id,
        :noteable_type => "Commit"
    end

    it "should save a valid note" do
      @note.noteable_id.should == commit.id
      @note.target.id.should == commit.id
    end
  end

  describe "Pre-line commit notes" do 
    before do 
      @note = Factory :note,
        :project => project,
        :noteable_id => commit.id,
        :noteable_type => "Commit", 
        :line_code => "OLD_1_23"
    end

    it "should save a valid note" do
      @note.noteable_id.should == commit.id
      @note.target.id.should == commit.id
    end

    it { @note.line_type_id.should == "OLD" }
    it { @note.line_file_id.should == 1 }
    it { @note.line_number.should == 23 }

    it { @note.for_line?(1, 23, 34).should be_true } 
    it { @note.for_line?(1, 23, nil).should be_true } 
    it { @note.for_line?(1, 23, 0).should be_true } 
    it { @note.for_line?(1, 23, 23).should be_true } 

    it { @note.for_line?(1, nil, 34).should be_false } 
    it { @note.for_line?(1, 24, nil).should be_false } 
    it { @note.for_line?(1, 24, 0).should be_false } 
    it { @note.for_line?(1, 24, 23).should be_false } 
  end

  describe :authorization do
    before do
      @p1 = project
      @p2 = Factory :project, :code => "alien", :path => "legit_1"
      @u1 = Factory :user
      @u2 = Factory :user
      @u3 = Factory :user
      @abilities = Six.new
      @abilities << Ability
    end

    describe :read do
      before do
        @p1.users_projects.create(:user => @u1, :project_access => Project::PROJECT_N)
        @p1.users_projects.create(:user => @u2, :project_access => Project::PROJECT_R)
        @p2.users_projects.create(:user => @u3, :project_access => Project::PROJECT_R)
      end

      it { @abilities.allowed?(@u1, :read_note, @p1).should be_false }
      it { @abilities.allowed?(@u2, :read_note, @p1).should be_true }
      it { @abilities.allowed?(@u3, :read_note, @p1).should be_false }
    end

    describe :write do
      before do
        @p1.users_projects.create(:user => @u1, :project_access => Project::PROJECT_R)
        @p1.users_projects.create(:user => @u2, :project_access => Project::PROJECT_RW)
        @p2.users_projects.create(:user => @u3, :project_access => Project::PROJECT_RW)
      end

      it { @abilities.allowed?(@u1, :write_note, @p1).should be_false }
      it { @abilities.allowed?(@u2, :write_note, @p1).should be_true }
      it { @abilities.allowed?(@u3, :write_note, @p1).should be_false }
    end

    describe :admin do
      before do
        @p1.users_projects.create(:user => @u1, :project_access => Project::PROJECT_R)
        @p1.users_projects.create(:user => @u2, :project_access => Project::PROJECT_RWA)
        @p2.users_projects.create(:user => @u3, :project_access => Project::PROJECT_RWA)
      end

      it { @abilities.allowed?(@u1, :admin_note, @p1).should be_false }
      it { @abilities.allowed?(@u2, :admin_note, @p1).should be_true }
      it { @abilities.allowed?(@u3, :admin_note, @p1).should be_false }
    end
  end
end
# == Schema Information
#
# Table name: notes
#
#  id            :integer         not null, primary key
#  note          :text
#  noteable_id   :string(255)
#  noteable_type :string(255)
#  author_id     :integer
#  created_at    :datetime
#  updated_at    :datetime
#  project_id    :integer
#  attachment    :string(255)
#  line_code     :string(255)
#

