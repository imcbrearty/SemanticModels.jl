using MacroTools
"""    findfunc(expr::Expr, name::Symbol)

findfunc walks the AST of `expr` to find the definition of function called `name`.

This function returns a reference to the original expression so that you can modify it inplace
and is intended to help users rewrite the definitions of functions for generating new models.
"""
function findfunc(expr::Expr, name::Symbol)  
    out = []
    MacroTools.postwalk(expr) do ex
        if (MacroTools.isexpr(ex, :function, :(=)) && MacroTools.namify(ex) == name)
            push!(out, ex)
        end
        return ex
    end
    return out
end

function findfunc(expr::LineNumberNode, s::Symbol)
    return nothing
end

function findfunc(args::Array{Expr, 1}, name::Symbol)
    out = []
    for arg in args
        out = vcat(out, findfunc(arg, name))
    end
    return out
end


walk(x, inner, outer) = outer(x)
walk(x::Expr, inner, outer) = outer(Expr(x.head, map(inner, x.args)...))

"""    findassign(expr::Expr, name::Symbol)

findassign walks the AST of `expr` to find the assignments to a variable called `name`.

This function returns a reference to the original expression so that you can modify it inplace
and is intended to help users rewrite expressions for generating new models.

See also: [`findfunc`](@ref).
"""
function findassign(expr::Expr, name::Symbol)
    # g(y) = filter(x->x!=nothing, y)
    matches = Expr[]
    g(y::Any) = :()
    f(x::Any) = :()
    f(x::Expr) = begin
        if x.head == :(=)
            if x.args[1] == name
                push!(matches, x)
                return x
            end

        end
        walk(x, f, g)
    end
    walk(expr, f, g)
    return matches
end

function replacevar(expr::Expr, name::Symbol, newname::Symbol)
    g(x::Any) = x
    f(x::Any) = x
    f(x::Symbol) = (x==name ? newname : x)
    f(x::Expr) = walk(x, f, g)
    return walk(expr, f, g)
end

function replacevar(expr::Expr, tr::Dict{Symbol, Any})
    g(x::Any) = x
    f(x::Any) = x
    f(x::Symbol) = get(tr, x, x)
    f(x::Expr) = walk(x, f, g)
    return walk(expr, f, g)
end
