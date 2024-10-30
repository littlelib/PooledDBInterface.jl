# PooledDBInterface.jl
Connection pool for DBInterface. Currently just for testing

# Examples
```julia
using PooledDBInterface, SQLite, DataFrames

# Create a connection pool from libraries that support DBInterface.jl. SQLite.jl is used in this example.

pool=PooledDBInterface(SQLite.DB, "test.sqlite", limit=16, numbers=6)

# You can execute sql queries like you do via DBInterface.
PooledDBInterface.execute(pool, "create table test (idx int, value text);")

# Use in a multithread context.
for i in 1:10
    Base.Threads.@spawn begin
        PooledDBInterface.execute(pool, "insert into test values (?, ?);", [i, "$i$i"])
    end
end

# If you need to acquire a specific connection to be used, you can manually acquire it via Base.acquire.
conn=Base.acquire(pool)
# Now you can use the DBInterface.Connection object(conn.conn).
SQLite.prepare(conn.conn, "insert into test values (?, ?);")
...
# Release the connection to pool when done with it.
Base.release(conn)

# Close all connections to the DB.
PooledDBInterface.close!(pool)
```