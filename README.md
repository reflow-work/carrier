# Carrier.Umbrella

## Setup Project

```shell
docker compose up -d
mix deps.get
mix setup
```

## Run Applications

```shell
iex -S mix phx.server
```

## Run Sample Job

```elixir
# Start

%{"scheduled_at" => DateTime.utc_now()}
|> CarrierWorker.SampleJob.new(meta: %{"type" => "sample"})
|> then(& Oban.insert(CarrierWorker.Oban, &1))

# Stop

# pause queue for finding the last job
Oban.pause_queue(CarrierWorker.Oban, queue: :sample)

# find the last job
import Ecto.Query

%{id: job_id} =
    Carrier.Repo.one(
        from oj in "oban_jobs",
        where: fragment(~s|meta @> '{"type":"sample"}'|) and oj.state != "completed",
        select: %{id: oj.id}
    )

# cancel the last job
Oban.cancel_job(CarrierWorker.Oban, job_id)

# resume queue
Oban.resume_queue(CarrierWorker.Oban, queue: :sample)
```
