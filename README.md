# PooledDBInterface.jl
Connection pool for DBInterface. Currently just for testing

# Examples
```julia
using PooledDBInterface, SQLite, DataFrames

# Create a connection pool from libraries that support DBInterface.jl. SQLite.jl is used in this example.

pool=PooledDBInterface.connect(SQLite.DB, "test.sqlite", limit=16, numbers=6)

# You can execute sql queries like you do via DBInterface.
PooledDBInterface.execute(pool, "create table test (idx int, value text);")
 
# If you need to acquire a specific connection to be used, you can manually acquire it via Base.acquire.
conn=Base.acquire(pool)
# Now you can use the DBInterface.Connection object(conn.conn).
SQLite.prepare(conn.conn, "insert into test values (?, ?);")
...
# Release the connection to pool when done with it.
Base.release(conn)


# Usage in a multithread context.
# It gets tricky when writing is involved in SQLite DB - multiple writes will create a "database is locked" SqliteException.
# One has to manually acquire a conn, set PRAGMA busy_timeout=2000 (or whichever is appropriate), execute the query and release it back to the pool.
# As you're dealing with multiple connections, each connection must have the proper PRAGMA option set before usage, and hence the Base.acquire.
for i in 1:10
    Base.Threads.@spawn begin
        conn=Base.acquire(pool)
        DBInterface.execute(conn.conn, "PRAGMA busy_timeout=2000;")
        DBInterface.execute(conn.conn, "insert into test values (?, ?);", [i, "$i$i"])
        Base.release(conn)
    end
end

PooledDBInterface.execute(pool, "select * from test;")|>DataFrame

# Close all connections to the DB.
PooledDBInterface.close!(pool)
```