# ---
# jupyter:
#   jupytext:
#     text_representation:
#       extension: .jl
#       format_name: light
#       format_version: '1.3'
#       jupytext_version: 1.0.4
#   kernelspec:
#     display_name: Julia 1.0.3
#     language: julia
#     name: julia-1.0
# ---

using Weave

const EXAMPLES_DIR = abspath(joinpath(@__DIR__, "..","..", "examples"))

const JMD_DIR = abspath(joinpath(@__DIR__,"examples","jmd"))

const HTML_DIR = abspath(joinpath(@__DIR__,"examples","html"))

# +
if isdir(JMD_DIR) 
    nothing
else 
    mkpath(JMD_DIR) 
end

if isdir(HTML_DIR) 
    nothing
else 
    mkpath(HTML_DIR) 
end
# -

run(`find $EXAMPLES_DIR -maxdepth 1 -name "*.jl" -exec jupytext "{}" --to ipynb ";" `)

function listnotebooks()
    [ i for i in readdir(EXAMPLES_DIR) if splitext(i)[end] == ".ipynb"]
end
nbs = listnotebooks()

function createjmd(nbs)
    for nb in nbs
    @info "Converting $nb to .jmd file"
    convert_doc("$(EXAMPLES_DIR)/$(nb)","$JMD_DIR/$(splitext(nb)[1]).jmd")
    end
end

function createhtml(nbs)
    for nb in nbs
    @info "Converting $nb to .html file"
    convert_doc("$(EXAMPLES_DIR)/$(nb)","$HTML_DIR/$(splitext(nb)[1]).html")
    end
end

createjmd(nbs)

createhtml(nbs)


