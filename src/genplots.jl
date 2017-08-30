export genplots, getexamples, runplotgen

@doc """ results = runplotgen()
Run full generation of the plots needed for the tests in ControlSystems.jl
""" ->
function runplotgen()
  funcs, refs, eps = getexamples()
  genplots(funcs, refs, eps=eps)
end

@doc """ results = genplots(funcs, refs; eps, kwargs...)
Generate the plots needed for the tests in ControlSystems.jl
""" ->
function genplots(funcs, refs; eps=0.01*ones(length(refs)), kwargs...)
    ENV["MPLBACKEND"] = "Agg"
    results = Array{VisualRegressionTests.VisualTestResult,1}(length(refs))
    #Run/generate tests
    for (i,ref) in enumerate(refs)
        testf(fn) = png(funcs[i](), fn)
        results[i] = test_images(VisualTest(testf, ref); eps=eps[i], kwargs...)
    end
    results
end

@doc """funcs, refs, eps = getexamples()
Get the example functions and locations of reference plots needed for the tests in ControlSystems.jl
""" ->
function getexamples()
    tf1 = tf([1],[1,1], inputnames=["Inp1"], outputnames=["Out1"])
    tf2 = tf([1/5,2],[1,1,1], inputnames=["Inp2"], outputnames=["Out1"])
    sys = [tf1 tf2]
    sysss = ss([-1 2; 0 1], [1 0; 1 1], [1 0; 0 1], [0.1 0; 0 -0.2],
        inputnames=["MyIn1", "MyIn2"], statenames=["State1", "State2"])

    ws = logspace(-2,2,200)
    ts = 0:0.01:5
    bodegen() = begin
      setPlotScale("dB")
      bodeplot(sys,ws)
    end
    nyquistgen() = nyquistplot(sysss,ws)
    sigmagen() = sigmaplot(sysss,ws)
    #Only siso for now
    nicholsgen() = nicholsplot(tf1,ws)

    stepgen() = stepplot(sys, ts[end], ts[2]-ts[1], l=(:dash, 4))
    impulsegen() = impulseplot(sys, ts[end], ts[2]-ts[1], l=:blue)
    L = lqr(sysss.A, sysss.B, eye(2), eye(2))
    lsimgen() = lsimplot(sysss, (i,x)->-L*x, ts, [1;2])

    margingen() = marginplot([tf1, tf2], ws)
    gangoffourgen() = begin
      setPlotScale("log10");
      gangoffourplot(tf1, [tf(1), tf(5)])
    end
    pzmapgen() = pzmap(tf2, xlims=(-15,5))
    rlocusgen() = rlocusplot(tf2)

    plotsdir = Pkg.dir("ControlExamplePlots")*"/src/figures/"
    refs = ["bode.png", "nyquist.png", "sigma.png", "nichols.png", "step.png",
            "impulse.png", "lsim.png", "margin.png", "gangoffour.png", "pzmap.png", "rlocus.png"]
    funcs = [bodegen, nyquistgen, sigmagen, nicholsgen, stepgen,
             impulsegen, lsimgen, margingen, gangoffourgen, pzmapgen, rlocusgen]
    eps = 0.001*ones(length(refs));
    funcs, map(s -> plotsdir*s, refs), eps
end
