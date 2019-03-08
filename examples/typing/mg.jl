using SemanticModels.Dubstep
using Cassette
using LightGraphs
using MetaGraphs

Cassette.@context TypeCtx
            
"""   TypeCtx

creates a MetaDiGraph tracking the types of args and ret values throughout a script

"""
TypeCtx
            
            

"""   FCollector(depth::Int,frame::function,data::FCollector)

struct to collect all the "frames" called throughout a script
        
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

a structure to hold metadata for recursive type information for each function call
Every frame can be thought of as a single stack frame when a function is called
            
"""
mutable struct Frame{F,T,U}
    func::F
    args::T
    ret::U
end
            
function Cassette.overdub(ctx::TypeCtx, f, args...) # add boilerplate for functionality
    c = FCollector(ctx.metadata.depth-1, Frame(f, typeof.(args), Any))
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

Cassette.canrecurse(ctx::Type{TypeCtx},::typeof(Base.vect), args...) = false # limit the stacktrace in terms of which to recurse on
Cassette.canrecurse(ctx::Type{TypeCtx},::typeof(FCollector)) = false
function Cassette.canrecurse(ctx::TypeCtx,
                             f::Union{typeof(+), typeof(*), typeof(/), typeof(-),typeof(Base.iterate),
                                      typeof(Base.sum),
                                      typeof(Base.mapreduce),
                                      typeof(Base.Broadcast.copy),
                                      typeof(Base.Broadcast.instantiate),
                                      typeof(Base.Math.throw_complex_domainerror),
                                      typeof(Base.Broadcast.broadcasted)},
                             args...)
    return false
end
                
"""    buildgraph

internal function used in the typegraphfrompath
takes the collector object and returns a metagraph
            
"""
function buildgraph(g,collector)
    try
        g[collector.frame.args,:label]
    catch
        add_vertex!(g,:label,collector.frame.args)
    end

    try 
        g[collector.frame.ret,:label]
    catch
        add_vertex!(g,:label,collector.frame.ret)
    end
    
    if !has_edge(g,g[collector.frame.args,:label],g[collector.frame.ret,:label])    
        add_edge!(g,g[collector.frame.args,:label],g[collector.frame.ret,:label],:label,collector.frame.func)
    end
                    
    for frame in collector.data
        buildgraph(g,frame)
    end
                    
    return g
end

"""    cleangraph(g::MetaDiGraph)

removes the nothings to replace them with strings for outputing an image
"""
function cleangraph(mg::MetaDiGraph)
    for vertex in vertices(mg)
        if get_prop(mg,vertex,:label) == nothing
            set_prop!(mg,vertex,:label,"missing")
        end
    end
    
    for edge in edges(mg)
        if get_prop(mg,edge,:label) == nothing
            set_prop!(mg,edge,:label,"missing")
        end
    end
    
    return mg
end
                            

"""    typegraph(path::AbstractString,maxdepth::Int)
            
This is a function that takes in an array of script and produces a MetaDiGraph descibing the system.
takes in optional parameter of recursion depth on the stacktrace defaulted to 3

"""
function typegraph(m::Module,maxdepth::Int=3)
    
    extractor = FCollector(maxdepth, Frame(nothing, (), nothing,)) # init the collector object     
    ctx = TypeCtx(metadata = extractor);     # init the context we want             
    Cassette.overdub(ctx,m.main);    # run the script internally and build the extractor data structure
    g = MetaDiGraph()    # crete a graph where we will init our tree
    set_indexing_prop!(g,:label)    # we want to set this metagraph to be able to index by the names
    g = buildgraph(g,extractor)    # pass the collector ds to make the acutal metagraph
    return cleangraph(g)
    
end

function escapehtml(i::AbstractString)
    # Refer to http://stackoverflow.com/a/7382028/3822752 for spec. links
    o = replace(i, "&" =>"&amp;")
    o = replace(o, "\""=>"&quot;")
    o = replace(o, "'" =>"&#39;")
    o = replace(o, "<" =>"&lt;")
    o = replace(o, ">" =>"&gt;")
    return o
end

function savedot(io::IOStream, g::MetaDiGraph)
    write(io, "digraph G {\nrankdir=\"LR\";\n")
    for p in props(g)
        write(io, "$(p[1])=$(escapehtml(string(p[2])));\n")
    end

    for v in vertices(g)
        write(io, "$v")
        if length(props(g, v)) > 0
            write(io, " [ ")
        end
        for p in props(g, v)
            key = p[1]
            write(io, "$key=\"$(escapehtml(string(p[2])))\",")
        end
        if length(props(g, v)) > 0
            write(io, "];")
        end
        write(io, "\n")
    end

    for e in edges(g)
        write(io, "$(src(e)) -> $(dst(e)) [ ")
        for p in props(g,e)
            write(io, "$(p[1])=\"$(escapehtml(string(p[2])))\", ")
        end
        write(io, "]\n")
    end
    write(io, "}\n")
end

function savegraph(fn::AbstractString, g::AbstractMetaGraph, ::DOTFormat)
    open(fn, "w") do fp 
        savedot(fp, g)
    end
end


file = "NHosts1Vector.jl"


include("./files/$file")
using Main.Example
mg = typegraph(Main.Example,100)
savegraph("$(file[1:end-3]).dot",mg,DOTFormat())
