# assumes that you have run galois.jl so that p, p2, p3 exist
using MacroTools
import MacroTools: postwalk
m = p.m
map(m.Λ) do λ
    @show λ
    body, args = @show Petri.funcbody(λ)
end

S, I, R = m.S

Δin  = [S+I, I, R]
Δout = [2I, R, S]

Δinm = [1 1 0;
        0 1 0;
        0 0 1]

Δoutm = [0 2 0;
        0 0 1;
        1 0 0]

du = (Δoutm - Δinm)'m.Λ

stripnullterms(e) = begin
    newex = MacroTools.postwalk(e) do ex
        if typeof(ex) != Expr; return ex end
        if ex.args[1] != :(*); return ex end
        if ex.args[2] != 0; return ex end
        if ex.args[2] == 0; return 0 end
        return ex
    end
    newex = MacroTools.postwalk(newex) do ex
        if typeof(ex) != Expr; return ex end
        if ex.args[1] != :(+); return ex end
        if ex.args[2] == 0
            return ex.args[3]
        end
        if ex.args[3] == 0
            return ex.args[2]
        end
        return ex
    end
    return newex
end

answer = map(enumerate(du)) do (i, ex)
    body, args = Petri.funcbody(ex)
    body′ = stripnullterms(body)
    state = m.S[i].op.name
    :(du.$(state) = $body′)
end
Petri.funckit(:f, (:du, :state, :p, :t), quote $(answer...)end )
