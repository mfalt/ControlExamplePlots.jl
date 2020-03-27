# GLOBALS that should be set
println("Running comment script!")
println("PR_ID is $(ENV["PR_ID"])")

# Set plot globals
ENV["PLOTS_TEST"] = "true"
ENV["GKSwstype"] = "100"

# Stolen from https://discourse.julialang.org/t/collecting-all-output-from-shell-commands/15592/6
""" Read output from terminal command """
function communicate(cmd::Cmd, input)
    inp = Pipe()
    out = Pipe()
    err = Pipe()

    process = run(pipeline(cmd, stdin=inp, stdout=out, stderr=err), wait=false)
    close(out.in)
    close(err.in)

    stdout = @async String(read(out))
    stderr = @async String(read(err))
    write(process, input)
    close(inp)
    wait(process)
    return (
        stdout = fetch(stdout),
        stderr = fetch(stderr),
        code = process.exitcode
    )
end

# Values
origin = "origin"
org = "mfalt" # JuliaControl
ID = ENV["PR_ID"]

using Pkg
# Makes sure we can push to this later
println("deving ControlExamplePlots")
Pkg.develop(Pkg.PackageSpec(url="https://github.com/$org/ControlExamplePlots.jl.git"))

println("adding packages")
Pkg.add("UUIDs")
Pkg.add("GitHub")

""" Checkout ControlSystems PR"""
function checkout_ControlSystems_PR(org, origin, ID)
    Pkg.develop(Pkg.PackageSpec(url="https://github.com/$org/ControlSystems.jl.git"))
    dir = joinpath(Pkg.devdir(), "ControlSystems")
    cd(dir)
    run(`git fetch $origin pull/$ID/head:tests-$ID`)
    run(`git checkout tests-$ID`)
    return
end

println("running checkout_ControlSystems_PR")
checkout_ControlSystems_PR(org, origin, ENV["PR_ID"])

println("using ControlExamplePlots")
using ControlExamplePlots

""" Generate figures for plot tests"""
function gen_figures()
    #### Test Plots

    ControlExamplePlots.Plots.gr()
    ControlExamplePlots.Plots.default(show=false)

    funcs, refs, eps = getexamples()
    # Make it easier to pass tests on different systems
    # Set to a factor 2 of common errors
    eps = [0.15, 0.015, 0.1, 0.01, 0.01, 0.02, 0.01, 0.15, 0.15, 0.01, 0.01]
    res = genplots(funcs, refs, eps=eps, popup=false)
    return res
end

println("running gen_figures")
res = gen_figures()

import UUIDs

function create_ControlExamplePlots_branch(ID)
    dir = joinpath(Pkg.devdir(), "ControlExamplePlots")
    cd(dir)
    master_sha1 = communicate(`git rev-parse HEAD`, "useless string")[1][1:end-1] # strip newline
    tmp_name = UUIDs.uuid1()
    # Create new branch
    new_branch_name = "tests-$ID-$tmp_name"
    run(`git checkout -b $new_branch_name`)
    return master_sha1, new_branch_name
end

println("running create_ControlExamplePlots_branch")
old_commit, new_branch_name = create_ControlExamplePlots_branch(ID)

""" Replace old files with new and push to new branch"""
function replace_and_push_files(org, origin, ID, new_branch_name)
    # Create dir for temporary figures
    dir = joinpath(Pkg.devdir(), "ControlExamplePlots")
    cd(dir)
    for r in res
        # Copy results into repo
        mv(r.testFilename, r.refFilename, force=true)
    end
    # Add figures
    run(`git add src/figures/*`)
    run(`git commit -m "automated plots test"`)
    run(`git remote set-url $origin https://JuliaControlBot:$(ENV["ACCESS_TOKEN_BOT"])@github.com/$org/ControlExamplePlots.jl.git`)
    run(`git push -u $origin $new_branch_name`)
    return
end

println("running replace_and_push_files")
replace_and_push_files(org, origin, ID, new_branch_name)

# Builds a message to post to github
function get_message(res, org, old_commit, new_branch_name)
    str = """This is an automated message.
    Plot tests were run, see results below.
    Difference | Reference Image | New Image
    -----------| ----------------| ---------
    """
    for r in res
        status = string(r.status)
        fig_name = basename(r.refFilename)
        #str *= "$(status[i]) | ![Reference](https://raw.githubusercontent.com/mfalt/ControlSystems.jl/tmp-plots-$(tmp_name)/tmpFigures/$(fig_names[i])) | ![New](https://raw.githubusercontent.com/mfalt/ControlSystems.jl/tmp-plots-$(tmp_name)/tmpFigures/new-$(fig_names[i]))\n"
        str *= "$(status) | ![Reference](https://raw.githubusercontent.com/$org/ControlExamplePlots.jl/$old_commit/src/figures/$(fig_name)) | ![New](https://raw.githubusercontent.com/$org/ControlExamplePlots.jl/$(new_branch_name)/src/figures/$(fig_name))\n"
    end
    return str
end

println("running get_message")
message = get_message(res, org, old_commit, new_branch_name)

#### Post Comment
import GitHub

""" Post comment with result to original PR """
function post_comment(org, message)
    token = ENV["ACCESS_TOKEN_BOT"]
    auth = GitHub.authenticate(token)
    #Push the comment
    GitHub.create_comment("$org/ControlSystems.jl", ID, :issue; auth = auth, params = Dict("body" => message))
end

println("running post_comment")
post_comment(org, message)

println("Done!")
