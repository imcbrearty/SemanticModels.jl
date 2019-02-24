module Dubstep

using Cassette
using LinearAlgebra
using LightGraphs
using MetaGraphs
export construct, TracedRun, trace, TraceCtx, LPCtx, replacenorm,
    GraftCtx, replacefunc, TypeCtx, typegraphfrompath

function construct(T::Type, args...)
    @info "constructing a model $T"
    return T(args...)
end

Cassette.@context TraceCtx

"""    TraceCtx

builds dynamic analysis traces of a model for information extraction
"""
TraceCtx

function Cassette.overdub(ctx::TraceCtx, args...)
    subtrace = Any[]
    push!(ctx.metadata, args => subtrace)
    if Cassette.canrecurse(ctx, args...)
        newctx = Cassette.similarcontext(ctx, metadata = subtrace)
        return Cassette.recurse(newctx, args...)
    else
        return Cassette.fallback(ctx, args...)
    end
end

function Cassette.overdub(ctx::TraceCtx, f::typeof(Base.vect), args...)
    @info "constructing a vector"
    push!(ctx.metadata, (f, args))
    return Cassette.fallback(ctx, f, args...)
end

function Cassette.overdub(ctx::TraceCtx, f::typeof(Core.apply_type), args...)
    # @info "applying a type $(args)"
    push!(ctx.metadata, (f, args))
    return Cassette.fallback(ctx, f, args...)
end

# TODO: support calls like construct(T, a, f(b))
function Cassette.overdub(ctx::TraceCtx, f::typeof(construct), args...)
    @info "constructing with type $f"
    push!(ctx.metadata, (f, args))
    y = Cassette.fallback(ctx, f, args...)
    @info "constructed model: $y"
    return y
end

"""    TracedRun{T,V}

captures the dataflow of a code execution. We store the trace and the value.

see also `trace`.
"""
struct TracedRun{T,V}
    trace::T
    value::V
end

"""    trace(f)

run the function f and return a TracedRun containing the trace and the output.
"""
function trace(f::Function)
    trace = Any[]
    val = Cassette.recurse(TraceCtx(metadata=trace), f)
    return TracedRun(trace, val)
end



Cassette.@context LPCtx

"""    LPCtx

replaces all calls to `LinearAlgebra.norm` with a different `p`.

This context is useful for modifying statistical codes or machine learning regularizers.
"""
LPCtx

function Cassette.overdub(ctx::LPCtx, args...)
    if Cassette.canrecurse(ctx, args...)
        newctx = Cassette.similarcontext(ctx, metadata = ctx.metadata)
        return Cassette.recurse(newctx, args...)
    else
        return Cassette.fallback(ctx, args...)
    end
end

function Cassette.overdub(ctx::LPCtx, f::typeof(norm), arg, power)
    p = get(ctx.metadata, power, power)
    return f(arg, p)
end

"""    replacenorm(f::Function, d::AbstractDict)

run f, but replace every call to norm using the mapping in d.
"""
function replacenorm(f::Function, d::AbstractDict)
    ctx = LPCtx(metadata=d)
    return Cassette.recurse(ctx, f)
end

Cassette.@context GraftCtx


"""    GraftCtx

grafts an expression from one simulation onto another

This context is useful for modifying simulations by changing out components to add features

see also: [`Dubstep.LPCtx`](@ref)
"""
GraftCtx

function Cassette.overdub(ctx::GraftCtx, f, args...)
    if Cassette.canrecurse(ctx, f, args...)
        newctx = Cassette.similarcontext(ctx, metadata = ctx.metadata)
        return Cassette.recurse(newctx, f, args...)
    else
        return Cassette.fallback(ctx, f, args...)
    end
end


"""    replacefunc(f::Function, d::AbstractDict)

run f, but replace every call to f using the context GraftCtx.
in order to change the behavior you overload overdub based on the context.
Metadata used to influence the context is stored in d.

see also: `bin/graft.jl` for an example.
"""
function replacefunc(f::Function, d::AbstractDict)
    ctx = GraftCtx(metadata=d)
    return Cassette.recurse(ctx, f)
end
            
#------------------------------------------------------------------------------------           
            
Cassette.@context TypeCtx
            
"""   TypeCtx

creates a MetaDiGraph tracking the types of args and ret values throughout a script

"""
TypeCtx
            
            

"""   FCollector(depth::Int,frame::function,data::FCollector)

struct to collect all the functions called throughout a script
        
"""
mutable struct FCollector{I,F,C}
    depth::I
    frame::F
    data::Vector{C}
end
            


"""   FCollector(depth::Int,frame::Frame)

this is an initialization funtion for the FCollector

"""
function FCollector(d::Int, f)
    FCollector(d, f, FCollector[])
end

""" Frame(func, args, ret, subtrace)

a structure to hold metadata for recursive type information for every function called
            
"""
mutable struct Frame{F,T,U}
    func::F
    args::T
    ret::U
end
            
# add boilerplate for functionality
function Cassette.overdub(ctx::TypeCtx, f, args...)
    c = FCollector(ctx.metadata.depth-1, Frame(f, args, Any))
    push!(ctx.metadata.data, c)
    if c.depth > 0 && Cassette.canrecurse(ctx, f, args...)
        newctx = Cassette.similarcontext(ctx, metadata = c)
        z = Cassette.recurse(newctx, f, args...)
        c.frame.ret = typeof(z)
        return z
    else
        z = Cassette.fallback(ctx, f, args...)
        c.frame.ret = typeof(z)
        return z
    end
end

# limit the stacktrace in terms of which to recurse on
Cassette.canrecurse(ctx::TypeCtx,::typeof(Base.vect), args...) = false
Cassette.canrecurse(ctx::TypeCtx,::typeof(FCollector)) = false
Cassette.canrecurse(ctx::TypeCtx,::typeof(Frame)) = false

# this is a function that strips all using statements from a raw text file
# reasons to do so
# 1) we no longer include libraries we dont have too so semanticmodels can remain small
# 2) prevents errors in the include-cassette design which doesn allow for usings
function extractdeps(filename::String)
    f = open(filename)
    newf = open("new$filename","w") 
    for line in readlines(f)
        if occursin("using",line)
            ex = Meta.parse(line)
            eval(ex)
        else
            write(newf,"$line\n")
        end
    end
    close(f)
    close(newf)
    return "new$filename"
end
                
""" buildgraph

internal function used in the typegraphfrompath
takes the collector object and returns a metagraph
            
"""
function buildgraph(g,collector)
    add_vertex!(g,:name,collector.frame.args)
    add_vertex!(g,:name,collector.frame.ret)
    add_edge!(g,nv(g)-1,nv(g),:name,collector.frame.func)
    for frame in collector.data
        buildgraph(g,frame)
    end
    return g
end

""" typegraph(path::AbstractString,maxdepth::Int)
            
This is a function that takes in an array of script and produces a MetaDiGraph descibing the system.
takes in optional parameter of recursion depth on the stacktrace defaulted to 3

"""
function typegraph(path::AbstractString,maxdepth::Int=3)
    
    # init the collector object
    extractor = FCollector(maxdepth, Frame(nothing, (), nothing,))
                
    # init the context we want
    ctx = TypeCtx(metadata = extractor);
    
    # build new script we want and load deps in env
    newpath = extractdeps(path)
                    
    # cassette requires a callable stack
    transcribe() = include(newpath)
                        
    # run the script internally and build the extractor data structure
    Cassette.overdub(ctx,transcribe);
                        
    # delete our file we created for eval
    rm(newpath)
    
    # crete a graph where we will init our tree
    g = MetaDiGraph()
    
    # pass the collector ds to make the acutal metagraph
    return buildgraph(g,extractor)
    
end

end #module

