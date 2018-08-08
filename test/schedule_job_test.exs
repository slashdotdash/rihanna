defmodule ScheduleJobTest do
  use ExUnit.Case, async: false

  import Rihanna
  import TestHelper
  alias Rihanna.Mocks.MockJob

  setup_all [:create_jobs_table]

  @term {IO, :puts, ["Work, work, work, work, work."]}
  @due_at DateTime.from_naive!(~N[2018-08-01 14:00:00.000000], "Etc/UTC")

  describe "`schedule_at/2` with mfa" do
    test "returns the job struct" do
      {:ok, job} = Rihanna.schedule_at(@term, @due_at)

      assert_job(job, @term)
    end

    test "inserts the job to the DB", %{pg: pg} do
      {:ok, job} = Rihanna.schedule_at(@term, @due_at)

      job = get_job_by_id(pg, job.id)

      assert_job(job, @term)
    end

    test "shows helpful error for invalid argument" do
      assert_raise ArgumentError, ~r/^Rihanna.schedule_at requires/, fn ->
        schedule_at("not a MFA", @due_at)
      end
    end
  end

  describe "`schedule_at/3` with module and arg" do
    test "returns the job struct" do
      {:ok, job} = Rihanna.schedule_at(MockJob, :arg, @due_at)

      assert_job(job, {Rihanna.Mocks.MockJob, :arg})
    end

    test "inserts the job to the DB", %{pg: pg} do
      {:ok, job} = Rihanna.schedule_at(MockJob, :arg, @due_at)

      job = get_job_by_id(pg, job.id)

      assert_job(job, {Rihanna.Mocks.MockJob, :arg})
    end

    test "shows helpful error for invalid argument" do
      assert_raise ArgumentError, ~r/^Rihanna.schedule_at requires/, fn ->
        schedule_at("not a module", [], @due_at)
      end
    end
  end

  defp assert_job(job, expected_term) do
    assert %Rihanna.Job{} = job
    assert %DateTime{} = job.enqueued_at
    assert job.due_at == @due_at
    assert job.fail_reason |> is_nil
    assert job.failed_at |> is_nil
    assert job.term == expected_term
  end
end
