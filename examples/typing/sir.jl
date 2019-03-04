module test
function sir_ode(du, u, p, t)  
    #Infected per-Capita Rate
    β = p[1]
    #Recover per-capita rate
    γ = p[2]
    
    #Susceptible Individuals
    S = u[1]
    #Infected by Infected Individuals
    I = u[2]
   
    du[1] = -β * S * I
    du[2] = β * S * I - γ * I
    du[3] = γ * I
end

using DifferentialEquations

function main()
#Pram = (Infected Per Capita Rate, Recover Per Capita Rate)
pram = [0.1,0.05]
#Initial Prams = (Susceptible Individuals, Infected by Infected Individuals)
init = [0.99,0.01,0.0]
tspan = (0.0,200.0)

sir_prob = ODEProblem(sir_ode, init, tspan, pram)

sir_sol = solve(sir_prob, saveat = 0.1);
end

end