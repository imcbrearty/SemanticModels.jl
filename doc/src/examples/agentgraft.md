
# Agent Based Simulation Augmentation

We can apply our model augmentation framework to models that are not defined as an analytical mathematical expression.
A widely used class of models for complex systems are *agent based* in that they have an explicit representation of the agents with states and functions to represent their behavior and interactions. This notebook examines how to apply model transformations to augment agent based simulations.

We are going to use the simulation in `examples/agentbased.jl` as a baseline simulation and add capabilities to the simulation with SemanticModels transformations. The simulation in question is an implementation of a basic SIRS model on a static population. We will make two augmentations.

1. Add *un estado de los muertos* or *a state for the dead*, transforming the model from SIRS to SIRD
2. Add *vital dynamics* a represented by net population growth

These changes to the model could easily be made by changing the source code to add the features. However, this notebook shows how those changes could be scripted by a scientist. As we all know, once you can automate a scientific task by introducing a new technology, you free the mind of the scientist for more productive thoughts.

In this case we are automating the implementation of model changes to free the scientist to think about *what augmentations to the model should I make?* instead of *how do I implement these augmentations?*


```julia
using SemanticModels.Parsers
using SemanticModels.ModelTools
import Base: push!
```

    loaded



```julia
samples = 7
nsteps = 10
finalcounts = Any[]
```




    0-element Array{Any,1}




```julia
println("Running Agent Based Simulation Augmentation Demo")
println("================================================")
println("demo parameters:\n\tsamples=$samples\n\tnsteps=$nsteps")
```

    Running Agent Based Simulation Augmentation Demo
    ================================================
    demo parameters:
    	samples=7
    	nsteps=10


## Baseline SIRS model

Here is the baseline model, which is read in from a text file. You could instead of using `parsefile` use a `quote/end` block to code up the baseline model in this script. 

<img src="https://docs.google.com/drawings/d/e/2PACX-1vSeA7mAQ-795lLVxCWXzbkFQaFOHMpwtB121psFV_2cSUyXPyKMtvDjssia82JvQRXS08p6FAMr1hj1/pub?w=1031&amp;h=309">


```julia
expr = parsefile("agentbased.jl")
m = model(ExpStateModel, expr.args[3].args[3])
println("\nRunning basic model")
AgentModels = eval(m.expr)
for i in 1:samples
    newsam, counts = AgentModels.main(nsteps)
    push!(finalcounts, (model=:basic, counts=counts))
end
```

    
    Running basic model
    Pair{Symbol,Int64}[:S=>7, :I=>3, :R=>0]
    Pair{Symbol,Int64}[:S=>4, :I=>6, :R=>0]
    Pair{Symbol,Int64}[:S=>1, :I=>5, :R=>4]
    Pair{Symbol,Int64}[:S=>4, :I=>2, :R=>4]
    Pair{Symbol,Int64}[:S=>5, :I=>1, :R=>4]
    Pair{Symbol,Int64}[:S=>4, :I=>4, :R=>2]
    Pair{Symbol,Int64}[:S=>1, :I=>3, :R=>6]
    Pair{Symbol,Int64}[:S=>5, :I=>0, :R=>5]
    Pair{Symbol,Int64}[:S=>8, :I=>0, :R=>2]
    Pair{Symbol,Int64}[:S=>9, :I=>0, :R=>1]
    newsam.agents = Symbol[:S, :S, :S, :S, :S, :S, :S, :S, :R, :S]
    Pair{Symbol,Int64}[:S=>7, :I=>3, :R=>0]
    Pair{Symbol,Int64}[:S=>5, :I=>4, :R=>1]
    Pair{Symbol,Int64}[:S=>3, :I=>6, :R=>1]
    Pair{Symbol,Int64}[:S=>2, :I=>8, :R=>0]
    Pair{Symbol,Int64}[:S=>0, :I=>9, :R=>1]
    Pair{Symbol,Int64}[:S=>0, :I=>3, :R=>7]
    Pair{Symbol,Int64}[:S=>3, :I=>1, :R=>6]
    Pair{Symbol,Int64}[:S=>7, :I=>1, :R=>2]
    Pair{Symbol,Int64}[:S=>8, :I=>0, :R=>2]
    Pair{Symbol,Int64}[:S=>8, :I=>1, :R=>1]
    newsam.agents = Symbol[:S, :S, :S, :S, :S, :R, :S, :I, :S, :S]
    Pair{Symbol,Int64}[:S=>8, :I=>2, :R=>0]
    Pair{Symbol,Int64}[:S=>6, :I=>3, :R=>1]
    Pair{Symbol,Int64}[:S=>2, :I=>7, :R=>1]
    Pair{Symbol,Int64}[:S=>1, :I=>4, :R=>5]
    Pair{Symbol,Int64}[:S=>3, :I=>1, :R=>6]
    Pair{Symbol,Int64}[:S=>7, :I=>0, :R=>3]
    Pair{Symbol,Int64}[:S=>3, :I=>4, :R=>3]
    Pair{Symbol,Int64}[:S=>4, :I=>2, :R=>4]
    Pair{Symbol,Int64}[:S=>4, :I=>2, :R=>4]
    Pair{Symbol,Int64}[:S=>3, :I=>5, :R=>2]
    newsam.agents = Symbol[:I, :R, :S, :I, :R, :I, :I, :S, :S, :I]
    Pair{Symbol,Int64}[:S=>7, :I=>3, :R=>0]
    Pair{Symbol,Int64}[:S=>3, :I=>6, :R=>1]
    Pair{Symbol,Int64}[:S=>1, :I=>5, :R=>4]
    Pair{Symbol,Int64}[:S=>4, :I=>3, :R=>3]
    Pair{Symbol,Int64}[:S=>4, :I=>4, :R=>2]
    Pair{Symbol,Int64}[:S=>4, :I=>3, :R=>3]
    Pair{Symbol,Int64}[:S=>2, :I=>4, :R=>4]
    Pair{Symbol,Int64}[:S=>3, :I=>2, :R=>5]
    Pair{Symbol,Int64}[:S=>6, :I=>1, :R=>3]
    Pair{Symbol,Int64}[:S=>5, :I=>2, :R=>3]
    newsam.agents = Symbol[:S, :S, :S, :I, :R, :R, :S, :S, :I, :R]
    Pair{Symbol,Int64}[:S=>8, :I=>2, :R=>0]
    Pair{Symbol,Int64}[:S=>5, :I=>4, :R=>1]
    Pair{Symbol,Int64}[:S=>6, :I=>2, :R=>2]
    Pair{Symbol,Int64}[:S=>6, :I=>2, :R=>2]
    Pair{Symbol,Int64}[:S=>2, :I=>6, :R=>2]
    Pair{Symbol,Int64}[:S=>1, :I=>5, :R=>4]
    Pair{Symbol,Int64}[:S=>2, :I=>4, :R=>4]
    Pair{Symbol,Int64}[:S=>4, :I=>3, :R=>3]
    Pair{Symbol,Int64}[:S=>6, :I=>2, :R=>2]
    Pair{Symbol,Int64}[:S=>4, :I=>5, :R=>1]
    newsam.agents = Symbol[:S, :S, :S, :S, :R, :I, :I, :I, :I, :I]
    Pair{Symbol,Int64}[:S=>10, :I=>0, :R=>0]
    Pair{Symbol,Int64}[:S=>5, :I=>5, :R=>0]
    Pair{Symbol,Int64}[:S=>2, :I=>7, :R=>1]
    Pair{Symbol,Int64}[:S=>2, :I=>1, :R=>7]
    Pair{Symbol,Int64}[:S=>5, :I=>0, :R=>5]
    Pair{Symbol,Int64}[:S=>7, :I=>1, :R=>2]
    Pair{Symbol,Int64}[:S=>5, :I=>3, :R=>2]
    Pair{Symbol,Int64}[:S=>6, :I=>2, :R=>2]
    Pair{Symbol,Int64}[:S=>6, :I=>2, :R=>2]
    Pair{Symbol,Int64}[:S=>5, :I=>3, :R=>2]
    newsam.agents = Symbol[:I, :S, :R, :I, :I, :S, :R, :S, :S, :S]
    Pair{Symbol,Int64}[:S=>10, :I=>0, :R=>0]
    Pair{Symbol,Int64}[:S=>8, :I=>2, :R=>0]
    Pair{Symbol,Int64}[:S=>7, :I=>2, :R=>1]
    Pair{Symbol,Int64}[:S=>6, :I=>2, :R=>2]
    Pair{Symbol,Int64}[:S=>6, :I=>2, :R=>2]
    Pair{Symbol,Int64}[:S=>7, :I=>1, :R=>2]
    Pair{Symbol,Int64}[:S=>6, :I=>4, :R=>0]
    Pair{Symbol,Int64}[:S=>3, :I=>6, :R=>1]
    Pair{Symbol,Int64}[:S=>1, :I=>5, :R=>4]
    Pair{Symbol,Int64}[:S=>3, :I=>3, :R=>4]
    newsam.agents = Symbol[:I, :R, :R, :S, :R, :I, :I, :S, :R, :S]



```julia
m
```




    ExpStateModel(
      states=:([:S, :I, :R]),
      agents=Expr[:(a = sm.agents), :(a = fill(:S, n))],
      transitions=Expr[:(T = Dict(:S => (x...->begin
                          #= none:103 =#
                          if rand(Float64) < stateload(x[1], :I)
                              :I
                          else
                              :S
                          end
                      end), :I => (x...->begin
                          #= none:104 =#
                          if rand(Float64) < ρ
                              :I
                          else
                              :R
                          end
                      end), :R => (x...->begin
                          #= none:105 =#
                          if rand(Float64) < μ
                              :R
                          else
                              :S
                          end
                      end)))]
    )



## Adding the Dead State

<img src="https://docs.google.com/drawings/d/e/2PACX-1vRUhrX6GzMzNRWr0GI3pDp9DvSqJVTDVpy9SNNBIB08b7Hyf9vaHobE2knrGPda4My9f_o9gncG34pF/pub?w=1028&amp;h=309">

We are going to add an additional state to the model to represent the infectious disease fatalities. The user must specify what that concept means in terms of the name for the new state and the behavior of that state. `D` is a terminal state for a finite automata.


```julia
println("\nThe system states are $(m.states.args)")
println("\nAdding un estado de los muertos")

put!(m, ExpStateTransition(:D, :((x...)->:D)))

println("\nThe system states are $(m.states.args)")
# once you are dead, you are dead forever
println("\nThere is no resurrection in this model")
println("\nInfected individuals recover or die in one step")

# replace!(m, ExpStateTransition(:I, :((x...)->rand(Bool) ? :D : :I)))
m[:I] = :((x...)->rand(Bool) ? :R : :D)
@show m[:I]
```

    
    The system states are Any[:(:S), :(:I), :(:R)]
    
    Adding un estado de los muertos
    
    The system states are Any[:(:S), :(:I), :(:R), :(:D)]
    
    There is no resurrection in this model
    
    Infected individuals recover or die in one step
    m[:I] = :(x...->begin
              #= In[15]:12 =#
              if rand(Bool)
                  :R
              else
                  :D
              end
          end)





    :(x...->begin
              #= In[15]:12 =#
              if rand(Bool)
                  :R
              else
                  :D
              end
          end)




```julia
println("\nRunning SIRD model")
AgentModels = eval(m.expr)
for i in 1:samples
    newsam, counts = AgentModels.main(nsteps)
    push!(finalcounts, (model=:sird, counts=counts))
end
```

    
    Running SIRD model
    Pair{Symbol,Int64}[:S=>10, :I=>0, :R=>0, :D=>0]
    Pair{Symbol,Int64}[:S=>9, :I=>1, :R=>0, :D=>0]
    Pair{Symbol,Int64}[:S=>8, :I=>1, :R=>1, :D=>0]
    Pair{Symbol,Int64}[:S=>8, :I=>0, :R=>2, :D=>0]
    Pair{Symbol,Int64}[:S=>5, :I=>4, :R=>1, :D=>0]
    Pair{Symbol,Int64}[:S=>4, :I=>2, :R=>2, :D=>2]
    Pair{Symbol,Int64}[:S=>6, :I=>0, :R=>2, :D=>2]
    Pair{Symbol,Int64}[:S=>7, :I=>0, :R=>1, :D=>2]
    Pair{Symbol,Int64}[:S=>5, :I=>3, :R=>0, :D=>2]
    Pair{Symbol,Int64}[:S=>3, :I=>2, :R=>0, :D=>5]
    newsam.agents = Symbol[:S, :D, :D, :I, :I, :D, :D, :D, :S, :S]
    Pair{Symbol,Int64}[:S=>9, :I=>1, :R=>0, :D=>0]
    Pair{Symbol,Int64}[:S=>6, :I=>3, :R=>0, :D=>1]
    Pair{Symbol,Int64}[:S=>4, :I=>2, :R=>2, :D=>2]
    Pair{Symbol,Int64}[:S=>5, :I=>1, :R=>2, :D=>2]
    Pair{Symbol,Int64}[:S=>7, :I=>0, :R=>1, :D=>2]
    Pair{Symbol,Int64}[:S=>7, :I=>0, :R=>1, :D=>2]
    Pair{Symbol,Int64}[:S=>8, :I=>0, :R=>0, :D=>2]
    Pair{Symbol,Int64}[:S=>6, :I=>2, :R=>0, :D=>2]
    Pair{Symbol,Int64}[:S=>2, :I=>4, :R=>1, :D=>3]
    Pair{Symbol,Int64}[:S=>2, :I=>1, :R=>2, :D=>5]
    newsam.agents = Symbol[:R, :S, :D, :D, :S, :I, :D, :D, :D, :R]
    Pair{Symbol,Int64}[:S=>10, :I=>0, :R=>0, :D=>0]
    Pair{Symbol,Int64}[:S=>7, :I=>3, :R=>0, :D=>0]
    Pair{Symbol,Int64}[:S=>7, :I=>0, :R=>1, :D=>2]
    Pair{Symbol,Int64}[:S=>8, :I=>0, :R=>0, :D=>2]
    Pair{Symbol,Int64}[:S=>4, :I=>4, :R=>0, :D=>2]
    Pair{Symbol,Int64}[:S=>2, :I=>2, :R=>4, :D=>2]
    Pair{Symbol,Int64}[:S=>4, :I=>1, :R=>3, :D=>2]
    Pair{Symbol,Int64}[:S=>4, :I=>0, :R=>3, :D=>3]
    Pair{Symbol,Int64}[:S=>6, :I=>1, :R=>0, :D=>3]
    Pair{Symbol,Int64}[:S=>5, :I=>1, :R=>1, :D=>3]
    newsam.agents = Symbol[:S, :S, :I, :S, :S, :D, :D, :R, :D, :S]
    Pair{Symbol,Int64}[:S=>8, :I=>2, :R=>0, :D=>0]
    Pair{Symbol,Int64}[:S=>5, :I=>3, :R=>1, :D=>1]
    Pair{Symbol,Int64}[:S=>5, :I=>1, :R=>0, :D=>4]
    Pair{Symbol,Int64}[:S=>5, :I=>0, :R=>1, :D=>4]
    Pair{Symbol,Int64}[:S=>5, :I=>1, :R=>0, :D=>4]
    Pair{Symbol,Int64}[:S=>4, :I=>1, :R=>0, :D=>5]
    Pair{Symbol,Int64}[:S=>2, :I=>2, :R=>1, :D=>5]
    Pair{Symbol,Int64}[:S=>2, :I=>1, :R=>1, :D=>6]
    Pair{Symbol,Int64}[:S=>2, :I=>0, :R=>2, :D=>6]
    Pair{Symbol,Int64}[:S=>3, :I=>1, :R=>0, :D=>6]
    newsam.agents = Symbol[:S, :S, :D, :S, :D, :D, :D, :D, :I, :D]
    Pair{Symbol,Int64}[:S=>6, :I=>4, :R=>0, :D=>0]
    Pair{Symbol,Int64}[:S=>5, :I=>1, :R=>3, :D=>1]
    Pair{Symbol,Int64}[:S=>6, :I=>1, :R=>2, :D=>1]
    Pair{Symbol,Int64}[:S=>3, :I=>3, :R=>3, :D=>1]
    Pair{Symbol,Int64}[:S=>2, :I=>2, :R=>3, :D=>3]
    Pair{Symbol,Int64}[:S=>4, :I=>0, :R=>2, :D=>4]
    Pair{Symbol,Int64}[:S=>5, :I=>1, :R=>0, :D=>4]
    Pair{Symbol,Int64}[:S=>5, :I=>0, :R=>1, :D=>4]
    Pair{Symbol,Int64}[:S=>6, :I=>0, :R=>0, :D=>4]
    Pair{Symbol,Int64}[:S=>6, :I=>0, :R=>0, :D=>4]
    newsam.agents = Symbol[:D, :D, :S, :S, :S, :S, :S, :D, :D, :S]
    Pair{Symbol,Int64}[:S=>8, :I=>2, :R=>0, :D=>0]
    Pair{Symbol,Int64}[:S=>5, :I=>3, :R=>0, :D=>2]
    Pair{Symbol,Int64}[:S=>5, :I=>0, :R=>1, :D=>4]
    Pair{Symbol,Int64}[:S=>5, :I=>0, :R=>1, :D=>4]
    Pair{Symbol,Int64}[:S=>6, :I=>0, :R=>0, :D=>4]
    Pair{Symbol,Int64}[:S=>4, :I=>2, :R=>0, :D=>4]
    Pair{Symbol,Int64}[:S=>3, :I=>1, :R=>0, :D=>6]
    Pair{Symbol,Int64}[:S=>3, :I=>0, :R=>0, :D=>7]
    Pair{Symbol,Int64}[:S=>3, :I=>0, :R=>0, :D=>7]
    Pair{Symbol,Int64}[:S=>3, :I=>0, :R=>0, :D=>7]
    newsam.agents = Symbol[:S, :D, :D, :D, :S, :D, :D, :S, :D, :D]
    Pair{Symbol,Int64}[:S=>6, :I=>4, :R=>0, :D=>0]
    Pair{Symbol,Int64}[:S=>3, :I=>3, :R=>2, :D=>2]
    Pair{Symbol,Int64}[:S=>4, :I=>0, :R=>2, :D=>4]
    Pair{Symbol,Int64}[:S=>5, :I=>0, :R=>1, :D=>4]
    Pair{Symbol,Int64}[:S=>2, :I=>3, :R=>1, :D=>4]
    Pair{Symbol,Int64}[:S=>1, :I=>1, :R=>3, :D=>5]
    Pair{Symbol,Int64}[:S=>2, :I=>0, :R=>2, :D=>6]
    Pair{Symbol,Int64}[:S=>2, :I=>0, :R=>2, :D=>6]
    Pair{Symbol,Int64}[:S=>4, :I=>0, :R=>0, :D=>6]
    Pair{Symbol,Int64}[:S=>4, :I=>0, :R=>0, :D=>6]
    newsam.agents = Symbol[:D, :D, :S, :D, :S, :S, :D, :D, :D, :S]


    WARNING: replacing module AgentModels.


Some utilities for manipulating functions at a higher level than expressions.


```julia
function bodyblock(expr::Expr)
    expr.head == :function || error("$expr is not a function definition")
    return expr.args[2].args
end

struct Func end

function push!(::Func, func::Expr, ex::Expr)
    push!(bodyblock(func), ex)
end
```




    push! (generic function with 86 methods)



## Population Growth

Another change we can make to our model is the introduction of population growth. Our model for population is that on each timestep, one new suceptible person will be added to the list of agents. We use the `tick!` function as an anchor point for this transformation.

<img src="https://docs.google.com/drawings/d/e/2PACX-1vRfLcbPPaQq6jmxheWApqidYte8FxK7p0Ebs2EyW2pY3ougNh5YiMjA0NbRMuGAIT5pD02WNEoOfdCd/pub?w=1005&amp;h=247">


```julia
println("\nAdding population growth to this model")
stepr = filter(x->isa(x,Expr), findfunc(m.expr, :tick!))[1]
@show stepr
push!(Func(), stepr, :(push!(sm.agents, :S)))
println("------------------------")
@show stepr;
```

    
    Adding population growth to this model
    stepr = :(function tick!(sm::StateModel)
          #= none:54 =#
          sm.loads = map((s->begin
                          #= none:54 =#
                          stateload(sm, s)
                      end), sm.states)
      end)
    ------------------------
    stepr = :(function tick!(sm::StateModel)
          #= none:54 =#
          sm.loads = map((s->begin
                          #= none:54 =#
                          stateload(sm, s)
                      end), sm.states)
          push!(sm.agents, :S)
      end)



```julia
println("\nRunning growth model")
AgentModels = eval(m.expr)
for i in 1:samples
    newsam, counts = AgentModels.main(nsteps)
    push!(finalcounts, (model=:growth, counts=counts))
end
```

    
    Running growth model
    Pair{Symbol,Int64}[:S=>7, :I=>4, :R=>0, :D=>0]
    Pair{Symbol,Int64}[:S=>7, :I=>1, :R=>1, :D=>3]
    Pair{Symbol,Int64}[:S=>6, :I=>3, :R=>0, :D=>4]
    Pair{Symbol,Int64}[:S=>7, :I=>0, :R=>1, :D=>6]
    Pair{Symbol,Int64}[:S=>9, :I=>0, :R=>0, :D=>6]
    Pair{Symbol,Int64}[:S=>6, :I=>4, :R=>0, :D=>6]
    Pair{Symbol,Int64}[:S=>6, :I=>1, :R=>2, :D=>8]
    Pair{Symbol,Int64}[:S=>8, :I=>0, :R=>2, :D=>8]
    Pair{Symbol,Int64}[:S=>10, :I=>0, :R=>1, :D=>8]
    Pair{Symbol,Int64}[:S=>11, :I=>0, :R=>1, :D=>8]
    newsam.agents = Symbol[:S, :D, :D, :D, :S, :D, :D, :D, :S, :R, :S, :D, :S, :S, :S, :D, :S, :S, :S, :S]
    Pair{Symbol,Int64}[:S=>11, :I=>0, :R=>0, :D=>0]
    Pair{Symbol,Int64}[:S=>11, :I=>1, :R=>0, :D=>0]
    Pair{Symbol,Int64}[:S=>10, :I=>2, :R=>1, :D=>0]
    Pair{Symbol,Int64}[:S=>9, :I=>3, :R=>0, :D=>2]
    Pair{Symbol,Int64}[:S=>8, :I=>2, :R=>2, :D=>3]
    Pair{Symbol,Int64}[:S=>10, :I=>1, :R=>2, :D=>3]
    Pair{Symbol,Int64}[:S=>11, :I=>1, :R=>2, :D=>3]
    Pair{Symbol,Int64}[:S=>10, :I=>3, :R=>1, :D=>4]
    Pair{Symbol,Int64}[:S=>12, :I=>0, :R=>0, :D=>7]
    Pair{Symbol,Int64}[:S=>13, :I=>0, :R=>0, :D=>7]
    newsam.agents = Symbol[:D, :S, :S, :S, :S, :D, :S, :S, :D, :S, :D, :S, :S, :D, :D, :S, :D, :S, :S, :S]
    Pair{Symbol,Int64}[:S=>11, :I=>0, :R=>0, :D=>0]
    Pair{Symbol,Int64}[:S=>9, :I=>3, :R=>0, :D=>0]
    Pair{Symbol,Int64}[:S=>5, :I=>5, :R=>0, :D=>3]
    Pair{Symbol,Int64}[:S=>1, :I=>5, :R=>1, :D=>7]
    Pair{Symbol,Int64}[:S=>3, :I=>0, :R=>4, :D=>8]
    Pair{Symbol,Int64}[:S=>6, :I=>0, :R=>2, :D=>8]
    Pair{Symbol,Int64}[:S=>8, :I=>0, :R=>1, :D=>8]
    Pair{Symbol,Int64}[:S=>9, :I=>1, :R=>0, :D=>8]
    Pair{Symbol,Int64}[:S=>9, :I=>1, :R=>0, :D=>9]
    Pair{Symbol,Int64}[:S=>10, :I=>0, :R=>1, :D=>9]
    newsam.agents = Symbol[:R, :S, :D, :S, :D, :D, :D, :D, :S, :D, :D, :D, :D, :S, :S, :S, :S, :S, :S, :S]
    Pair{Symbol,Int64}[:S=>8, :I=>3, :R=>0, :D=>0]
    Pair{Symbol,Int64}[:S=>6, :I=>3, :R=>2, :D=>1]
    Pair{Symbol,Int64}[:S=>6, :I=>1, :R=>2, :D=>4]
    Pair{Symbol,Int64}[:S=>8, :I=>0, :R=>1, :D=>5]
    Pair{Symbol,Int64}[:S=>8, :I=>1, :R=>1, :D=>5]
    Pair{Symbol,Int64}[:S=>10, :I=>0, :R=>1, :D=>5]
    Pair{Symbol,Int64}[:S=>10, :I=>1, :R=>1, :D=>5]
    Pair{Symbol,Int64}[:S=>11, :I=>0, :R=>1, :D=>6]
    Pair{Symbol,Int64}[:S=>13, :I=>0, :R=>0, :D=>6]
    Pair{Symbol,Int64}[:S=>13, :I=>1, :R=>0, :D=>6]
    newsam.agents = Symbol[:S, :D, :S, :S, :D, :S, :S, :D, :S, :D, :S, :D, :S, :S, :D, :S, :S, :S, :I, :S]
    Pair{Symbol,Int64}[:S=>10, :I=>1, :R=>0, :D=>0]
    Pair{Symbol,Int64}[:S=>10, :I=>1, :R=>1, :D=>0]
    Pair{Symbol,Int64}[:S=>9, :I=>3, :R=>1, :D=>0]
    Pair{Symbol,Int64}[:S=>10, :I=>1, :R=>2, :D=>1]
    Pair{Symbol,Int64}[:S=>12, :I=>0, :R=>2, :D=>1]
    Pair{Symbol,Int64}[:S=>14, :I=>1, :R=>0, :D=>1]
    Pair{Symbol,Int64}[:S=>14, :I=>1, :R=>0, :D=>2]
    Pair{Symbol,Int64}[:S=>13, :I=>2, :R=>1, :D=>2]
    Pair{Symbol,Int64}[:S=>15, :I=>0, :R=>0, :D=>4]
    Pair{Symbol,Int64}[:S=>16, :I=>0, :R=>0, :D=>4]
    newsam.agents = Symbol[:D, :S, :D, :S, :S, :S, :S, :S, :S, :D, :S, :S, :D, :S, :S, :S, :S, :S, :S, :S]
    Pair{Symbol,Int64}[:S=>11, :I=>0, :R=>0, :D=>0]
    Pair{Symbol,Int64}[:S=>11, :I=>1, :R=>0, :D=>0]
    Pair{Symbol,Int64}[:S=>12, :I=>0, :R=>0, :D=>1]
    Pair{Symbol,Int64}[:S=>12, :I=>1, :R=>0, :D=>1]
    Pair{Symbol,Int64}[:S=>10, :I=>3, :R=>0, :D=>2]
    Pair{Symbol,Int64}[:S=>11, :I=>0, :R=>0, :D=>5]
    Pair{Symbol,Int64}[:S=>12, :I=>0, :R=>0, :D=>5]
    Pair{Symbol,Int64}[:S=>12, :I=>1, :R=>0, :D=>5]
    Pair{Symbol,Int64}[:S=>13, :I=>0, :R=>1, :D=>5]
    Pair{Symbol,Int64}[:S=>15, :I=>0, :R=>0, :D=>5]
    newsam.agents = Symbol[:S, :S, :S, :D, :D, :S, :S, :S, :D, :D, :S, :S, :S, :D, :S, :S, :S, :S, :S, :S]
    Pair{Symbol,Int64}[:S=>10, :I=>1, :R=>0, :D=>0]
    Pair{Symbol,Int64}[:S=>8, :I=>3, :R=>0, :D=>1]
    Pair{Symbol,Int64}[:S=>9, :I=>0, :R=>1, :D=>3]
    Pair{Symbol,Int64}[:S=>11, :I=>0, :R=>0, :D=>3]
    Pair{Symbol,Int64}[:S=>12, :I=>0, :R=>0, :D=>3]
    Pair{Symbol,Int64}[:S=>12, :I=>1, :R=>0, :D=>3]
    Pair{Symbol,Int64}[:S=>10, :I=>3, :R=>0, :D=>4]
    Pair{Symbol,Int64}[:S=>10, :I=>1, :R=>2, :D=>5]
    Pair{Symbol,Int64}[:S=>12, :I=>1, :R=>1, :D=>5]
    Pair{Symbol,Int64}[:S=>10, :I=>4, :R=>0, :D=>6]
    newsam.agents = Symbol[:S, :S, :S, :S, :D, :S, :S, :I, :D, :I, :D, :S, :I, :S, :S, :D, :D, :D, :I, :S]


    WARNING: replacing module AgentModels.


## Presentation of results

We have accumulated all of our simulation runs into the list `finalcounts` we process those simulation runs into summary tables describing the results of those simulations. This table can be used to make decisions and drive further inquiry.


```julia
println("\nModel\t Counts")
println("-----\t ------")
for result in finalcounts
    println("$(result.model)\t$(result.counts)")
end

function groupagg(x::Vector{Tuple{S,T}}) where {S,T}
    c = Dict{S, Tuple{Int, T}}()
    # c2 = Dict{S, T}()
    for r in x
        g = first(r)
        c[g] = get(c, g,(0, 0.0)) .+ (1, last(r))
    end
    return c
end

mean_healthy_frac = [(r.model,
                  map(last, filter(x->(x.first == :R || x.first == :S), r.counts))[1] / sum(map(last, r.counts))[1])
                 for r in finalcounts] |> groupagg

num_unhealthy = [(r.model,
                  map(last,
                      sum(map(last, filter(x->(x.first != :R && x.first != :S),
                             r.counts)))))
                 for r in finalcounts] |> groupagg

println("\nModel\t Count \t Num Unhealthy \t Mean Healthy %")
println("-----\t ------\t --------------\t  --------------")
for (g, v) in mean_healthy_frac
    μ = last(v)/first(v)
    μ′ = round(μ*100, sigdigits=5)
    x = round(last(num_unhealthy[g]) / first(num_unhealthy[g]), sigdigits=5)
    println("$g\t   $(first(v))\t  $(rpad(x, 6))\t   $(μ′)")
end
```

    
    Model	 Counts
    -----	 ------
    basic	Pair{Symbol,Int64}[:S=>9, :I=>0, :R=>1]
    basic	Pair{Symbol,Int64}[:S=>8, :I=>1, :R=>1]
    basic	Pair{Symbol,Int64}[:S=>3, :I=>5, :R=>2]
    basic	Pair{Symbol,Int64}[:S=>5, :I=>2, :R=>3]
    basic	Pair{Symbol,Int64}[:S=>4, :I=>5, :R=>1]
    basic	Pair{Symbol,Int64}[:S=>5, :I=>3, :R=>2]
    basic	Pair{Symbol,Int64}[:S=>3, :I=>3, :R=>4]
    sird	Pair{Symbol,Int64}[:S=>3, :I=>2, :R=>0, :D=>5]
    sird	Pair{Symbol,Int64}[:S=>2, :I=>1, :R=>2, :D=>5]
    sird	Pair{Symbol,Int64}[:S=>5, :I=>1, :R=>1, :D=>3]
    sird	Pair{Symbol,Int64}[:S=>3, :I=>1, :R=>0, :D=>6]
    sird	Pair{Symbol,Int64}[:S=>6, :I=>0, :R=>0, :D=>4]
    sird	Pair{Symbol,Int64}[:S=>3, :I=>0, :R=>0, :D=>7]
    sird	Pair{Symbol,Int64}[:S=>4, :I=>0, :R=>0, :D=>6]
    growth	Pair{Symbol,Int64}[:S=>11, :I=>0, :R=>1, :D=>8]
    growth	Pair{Symbol,Int64}[:S=>13, :I=>0, :R=>0, :D=>7]
    growth	Pair{Symbol,Int64}[:S=>10, :I=>0, :R=>1, :D=>9]
    growth	Pair{Symbol,Int64}[:S=>13, :I=>1, :R=>0, :D=>6]
    growth	Pair{Symbol,Int64}[:S=>16, :I=>0, :R=>0, :D=>4]
    growth	Pair{Symbol,Int64}[:S=>15, :I=>0, :R=>0, :D=>5]
    growth	Pair{Symbol,Int64}[:S=>10, :I=>4, :R=>0, :D=>6]
    
    Model	 Count 	 Num Unhealthy 	 Mean Healthy %
    -----	 ------	 --------------	  --------------
    growth	   7	  7.1429	   62.857
    sird	   7	  5.8571	   37.143
    basic	   7	  2.7143	   52.857

