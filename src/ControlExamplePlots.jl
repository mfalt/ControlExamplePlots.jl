module ControlExamplePlots

Pkg.status("VisualRegressionTests") == nothing &&
  error("VisualRegressionTests needs to be installed, get it at https://github.com/tbreloff/VisualRegressionTests.jl")

using ControlSystems, Plots, VisualRegressionTests

include("genplots.jl")

end # module
