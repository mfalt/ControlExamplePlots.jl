module ControlExamplePlots

try
    Pkg.installed("VisualRegressionTests")
catch
    warning("VisualRegressionTests needs to be installed to test plots, adding now:")
    Pkg.clone("https://github.com/tbreloff/VisualRegressionTests.jl.git")
end

using ControlSystems, Plots, VisualRegressionTests

include("genplots.jl")

end # module
