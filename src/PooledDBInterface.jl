module PooledDBInterface

using DBInterface, ConcurrentUtilities, Base

mutable struct ConnectionPool{T<:DBInterface.Connection}
    pool::Pool{Nothing, T}
    args
    keyargs
end

struct AcquiredConnection{T<:DBInterface.Connection}
    conn::T
    pool::Pool{Nothing, T}
end

function connect(args...;limit::Int=4096, numbers::Int=1, keyargs...)
    if numbers < 1
        err("There must be more than 1 connection to a pool.")
    elseif numbers > limit
        err("Number of initial connections can't exceed the limit")
    end
    conn=DBInterface.connect(args...;keyargs...)
    pool=Pool{typeof(conn)}(limit)
    Base.release(pool, Base.acquire(()->conn, pool, forcenew=true))
    foreach(1:numbers-1) do _
        Base.release(pool, Base.acquire(()->DBInterface.connect(args...;keyargs...), pool, forcenew=true))
    end
    return ConnectionPool{typeof(conn)}(pool, args, keyargs)
end

function execute(pool::ConnectionPool, args...;keyargs...)
    conn=Base.acquire(()->DBInterface.connect(pool.args...;pool.keyargs...), pool.pool)
    try
        return DBInterface.execute(conn, args...;keyargs...)
    finally
        Base.release(pool.pool, conn)
    end
end

function close!(pool::ConnectionPool)
    pool=pool.pool
    Base.@lock pool.lock begin
        if ConcurrentUtilities.Pools.iskeyed(pool)
            for objs in values(pool.keyedvalues)
                foreach(x->DBInterface.close!(x), objs) 
                empty!(objs)
            end
        else
            foreach(x->DBInterface.close!(x), pool.values)
            empty!(pool.values)
        end
    end
end

function Base.acquire(pool::ConnectionPool{T}) where {T<:DBInterface.Connection}
    AcquiredConnection{T}(Base.acquire(()->DBInterface.connect(pool.args...;pool.keyargs...), pool.pool), pool.pool)
end

function Base.release(conn::AcquiredConnection)
    Base.release(conn.pool, conn.conn)
end

end # module PooledDBInterface
