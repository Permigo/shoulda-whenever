module Shoulda
  module Whenever
    def schedule(task)
      ScheduleMatcher.new(task)
    end

    alias_method :schedule_rake, :schedule
    alias_method :schedule_runner, :schedule
    alias_method :schedule_command, :schedule

    class ScheduleMatcher
      attr_reader :duration, :time, :task, :roles

      def initialize(task)
        @task = task
        @duration = nil
        @time = nil
        @roles = nil
      end

      def matches?(subject)
        jobs = subject.instance_variable_get("@jobs")

        jobs = filter_jobs_by_duration(jobs)
        jobs = filter_jobs_by_time(jobs)
        jobs = filter_jobs_by_roles(jobs)
        jobs = filter_jobs_by_task(jobs)

        jobs.any?
      end

      def filter_jobs_by_duration(jobs)
        if duration.nil?
          jobs.values.flatten
        else
          jobs[duration]
        end
      end

      def filter_jobs_by_time(jobs)
        return jobs if time.nil?

        jobs.select { |job| job.at == time }
      end

      def filter_jobs_by_roles(jobs)
        return jobs if roles.nil? || roles.empty?

        jobs.select { |job| job.roles == roles }
      end

      def filter_jobs_by_task(jobs)
        jobs.select do |job|
          job.instance_variable_get("@options")[:task] == task
        end
      end

      def every(duration)
        @duration = duration

        self
      end

      def at(time)
        @time = time

        self
      end

      def with_roles(roles)
        @roles = Array(roles)

        self
      end
      alias_method :with_role, :with_roles

      def description
        [
          base_description,
          duration_description,
          time_description,
          roles_description
        ].compact.join(' ')
      end

      def failure_message
        [
          base_failure_message,
          duration_description,
          time_description,
          roles_description
        ].compact.join(' ')
      end

      def failure_message_when_negated
        [
          base_failure_message_when_negated,
          duration_description,
          time_description,
          roles_description
        ].compact.join(' ')
      end

      private

      def base_description
        "schedule \"#{ task }\""
      end

      def duration_description
        unless duration.nil?
          if duration.is_a?(String) || duration.is_a?(Symbol)
            "every \"#{ duration }\""
          else
            "every #{ duration.to_i } seconds"
          end
        end
      end

      def time_description
        unless time.nil?
          "at \"#{ time }\""
        end
      end

      def roles_description
        unless roles.nil? || roles.empty?
          role_names = roles.map { |role| "\"#{ role }\"" }.join(", ")

          "with #{ role_names } role(s)"
        end
      end

      def base_failure_message
        "expected to schedule \"#{ task }\""
      end

      def base_failure_message_when_negated
        "expected not to schedule \"#{ task }\""
      end
    end
  end
end
