# Carrier.Umbrella

## Setup Project

```shell
asdf install
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

## Deploy

### Assemble Elixir Release

`./bin/release <GITHUB_TOKEN> <branch> <env>`

ex) `./bin/release <GITHUB_TOKEN> prod main`

`<branch>` 는 `main`, `<env>` 는 `prod` 가 default 로, 생략 가능합니다.

### Deploy Elixir Release

`./bin/deploy <env> <version>`

ex) `./bin/deploy prod 0.1.0`

### Connect to machine

`./bin/connect <env>`

ex) `./bin/connect prod`

### Run DB Migration

```
$ ./app/current/bin/carrier_app eval "Carrier.Release.migrate()"
```
