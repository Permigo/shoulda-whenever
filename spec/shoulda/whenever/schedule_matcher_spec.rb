require "spec_helper"
require "whenever"
require "shoulda/whenever/schedule_matcher"
require "rspec/matchers/fail_matchers"
require "pry"

RSpec.configure do |config|
  config.include Shoulda::Whenever
  config.include RSpec::Matchers::FailMatchers
end

describe Shoulda::Whenever::ScheduleMatcher do
  let(:whenever) { Whenever::JobList.new(string: schedule_string) }

  describe "#description" do
    context "basic schedule check" do
      it "includes the task being scheduled" do
        expect(described_class.new("rake:every:10:minutes").description).to eq("schedule \"rake:every:10:minutes\"")
      end
    end

    context "with a duration" do
      it "includes the duration at which the task is being scheduled" do
        expect(
          described_class.new("rake:every:10:minutes")
          .every(Whenever::NumericSeconds.seconds(10, "minutes"))
                         .description
        ).to eq("schedule \"rake:every:10:minutes\" every 600 seconds")
      end
    end

    context "with a time to run" do
      it "includes the time at which the task is scheduled to run" do
        expect(
          described_class.new("rake:every:10:minutes")
                         .at("12:00 PM")
                         .description
        ).to eq("schedule \"rake:every:10:minutes\" at \"12:00 PM\"")
      end
    end

    context "with a cron schedule" do
      it "includes the schedule" do
        expect(
          described_class.new("rake:every:1:day:at:noon")
                         .every("0 0 27-31 * *")
                         .description
        ).to eq("schedule \"rake:every:1:day:at:noon\" every \"0 0 27-31 * *\"")
      end
    end

    context "with a time to run and a duration" do
      it "includes the time at which to run and how often to run it" do
        expect(
          described_class.new("rake:every:1:day:at:noon")
                         .every(Whenever::NumericSeconds.seconds(1, "day"))
                         .at("12:00 PM")
                         .description
        ).to eq("schedule \"rake:every:1:day:at:noon\" every 86400 seconds at \"12:00 PM\"")
      end
    end
  end

  context "a task that is not scheduled" do
    let(:schedule_string) { "" }

    it "passes" do
      expect(whenever).not_to schedule("MyTask.run")
    end

    it "fails" do
      expect {
        expect(whenever).to schedule("MyTask.run")
      }.to fail_with("expected to schedule \"MyTask.run\"")
    end
  end

  context "a task that is scheduled" do
    let(:schedule_string) do
      <<-SCHEDULE
        every 3.hours do
          rake "rake:every:3:hours"
        end
      SCHEDULE
    end

    it "passes" do
      expect(whenever).to schedule("rake:every:3:hours")
    end

    it "fails" do
      expect {
        expect(whenever).not_to schedule("rake:every:3:hours")
      }.to fail_with("expected not to schedule \"rake:every:3:hours\"")
    end
  end

  context "a task that is scheduled after a certain duration" do
    let(:schedule_string) do
      <<-SCHEDULE
        every 3.hours do
          rake "rake:every:3:hours"
        end
      SCHEDULE
    end

    it "passes" do
      expect(whenever).to schedule("rake:every:3:hours").every(Whenever::NumericSeconds.seconds(3, "hours"))
    end
     it "fails" do
       expect {
         expect(whenever).not_to schedule("rake:every:3:hours").every(Whenever::NumericSeconds.seconds(3, "hours"))
       }.to fail_with("expected not to schedule \"rake:every:3:hours\" every 10800 seconds")
     end
  end

  context "a task that is scheduled to run at a certain time" do
    let(:schedule_string) do
      <<-SCHEDULE
        every 1.day, at: "12:00 PM" do
          rake "rake:every:day:at:noon"
        end
      SCHEDULE
    end

    it "passes" do
      expect(whenever).to schedule("rake:every:day:at:noon").every(Whenever::NumericSeconds.seconds(1, "day")).at("12:00 PM")
    end

    it "fails" do
      expect {
        expect(whenever).not_to schedule("rake:every:day:at:noon").every(Whenever::NumericSeconds.seconds(1, "day")).at("12:00 PM")
      }.to fail_with("expected not to schedule \"rake:every:day:at:noon\" every 86400 seconds at \"12:00 PM\"")
    end
  end
end
