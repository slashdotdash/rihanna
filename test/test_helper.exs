{:ok, _} = Application.ensure_all_started(:postgrex)

{:ok, _} =
  Postgrex.start_link(
    Application.fetch_env!(:rihanna, :postgrex)
    |> Keyword.put(:name, Rihanna.Job.Postgrex)
  )

ExUnit.start()

defmodule TestHelper do
  defmacro assert_unordered_list_equality(list_1, list_2) do
    quote do
      assert Enum.sort(unquote(list_1)) == Enum.sort(unquote(list_2))
    end
  end

  def create_jobs_table(_ctx) do
    {:ok, pg} = Postgrex.start_link(Application.fetch_env!(:rihanna, :postgrex))

    drop_sqls = [
      """
      DROP TABLE IF EXISTS "rihanna_jobs";
      """,
      """
      DROP SEQUENCE IF EXISTS rihanna_jobs_id_seq
      """
    ]

    create_sqls = Rihanna.Migration.statements()

    for statement <- drop_sqls, do: Postgrex.query!(pg, statement, [])
    for statement <- create_sqls, do: Postgrex.query!(pg, statement, [])

    {:ok, %{pg: pg}}
  end

  def truncate_postgres_jobs(ctx) do
    Postgrex.query!(
      ctx.pg,
      """
      TRUNCATE "rihanna_jobs
      """,
      []
    )

    :ok
  end

  def get_job_by_id(pg, id) when is_pid(pg) and is_integer(id) do
    %{rows: rows} =
      Postgrex.query!(
        pg,
        """
        SELECT * FROM rihanna_jobs WHERE id = $1
        """,
        [id]
      )

    case Rihanna.Job.from_sql(rows) do
      [job] -> job
      [] -> nil
    end
  end

  @test_term {Kernel, :+, [1, 1]}

  def insert_job(pg, :ready_to_run) do
    result =
      Postgrex.query!(
        pg,
        """
          INSERT INTO "rihanna_jobs" (term, enqueued_at)
          VALUES ($1, '2018-01-01')
          RETURNING *
        """,
        [:erlang.term_to_binary(@test_term)]
      )

    [job] = Rihanna.Job.from_sql(result.rows)

    job
  end

  def insert_job(pg, :failed) do
    result =
      Postgrex.query!(
        pg,
        """
        INSERT INTO "rihanna_jobs" (
          term,
          enqueued_at,
          failed_at,
          fail_reason
        )
        VALUES ($1, '2018-01-01', '2018-01-02', 'Kaboom!')
        RETURNING *
        """,
        [:erlang.term_to_binary(@test_term)]
      )

    [job] = Rihanna.Job.from_sql(result.rows)

    job
  end
end
