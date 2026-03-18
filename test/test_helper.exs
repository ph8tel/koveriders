ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(KoveRiders.Repo, :manual)

# Define Mox mocks used by storage error-path tests
Mox.defmock(KoveRiders.MockStorage, for: KoveRiders.Storage)
