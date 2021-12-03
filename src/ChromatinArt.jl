module ChromatinArt

using Random
using Luxor
using Colors

function idx_to_zero_x(width::Int64, idx::Int64)::Int64
    return (idx - 1) % width
end
function idx_to_zero_y(width::Int64, idx::Int64)::Int64
    return trunc(Int64, (idx - 1) / width)
end
function zero_xy_to_idx(width::Int64, x::Int64, y::Int64)::Int64
    return x + y * width + 1
end

# Inspired by https://aip.scitation.org/doi/10.1063/1.2357935
function hamiltonian_mc_step!(path, width::Int64, height::Int64, dir::Int64, aux1::Int64, rng)
    if rand(rng) > 0.5
        # Reverse the list before we start
        reverse!(path)
    end
    # Try to step away from the head
    dir = rand(rng, 1:4)
    x = idx_to_zero_x(width,path[1])
    y = idx_to_zero_y(width,path[1])
    if dir == 1
        x = x + 1
    elseif dir == 2
        x = x - 1
    elseif dir == 3
        y = y + 1
    elseif dir == 4
        y = y - 1
    end

    if x < 0 || x >= width || y < 0 || y >= height
        return
    end
    # Otherwise, make a step
    aux1 = 0
    for i = 1:length(path)
        if path[i] == zero_xy_to_idx(width, x, y)
            aux1 = i
        end
    end
    reverse!(path, 1, aux1 - 1)
end

function generate_path(width::Int64, height::Int64, inputs::Vector{Int64}, outputs::Vector{Int64}, rng)::Vector{Int64}
    result = Vector{Int64}(1:(width*height))
    generate_path!(result, width, height, inputs, outputs, rng)
    return result
end

function generate_path!(path_array, width::Int64, height::Int64, inputs::Vector{Int64}, outputs::Vector{Int64}, rng)
    n_tiles = width * height
    # Init a Hamiltonian path
    path_array[1:end] = 1:n_tiles
    # Reverse every other row to get a Hamiltonian starting path
    for row in 2:2:height
        reverse!(path_array, 1 + (row - 1) * width, row * width)
    end

    aux1::Int64 = 0
    aux2::Int64 = 0

    # Initialize by doing some random iterations
    for i in 1:(n_tiles * 10)
        hamiltonian_mc_step!(path_array, width, height, aux1, aux2, rng)
    end

    while path_array[1] ∉ inputs  || path_array[end] ∉ outputs 
        hamiltonian_mc_step!(path_array, width, height, aux1, aux2, rng)
    end
end

struct FractalStructure
    width::Int64
    height::Int64
    n_levels::Int64
    sides::Vector{Vector{Int64}}
end

function Fractal(width::Int64, height::Int64, levels::Int64)::FractalStructure
    return FractalStructure(
        width,
        height,
        levels,
        [
            Vector(1:width),
            Vector(width:width:(width * height)),
            Vector((width * (height - 1) + 1):(width * height)),
            Vector(1:width:(width * (height - 1) + 1))
        ]
    )
end

struct FractalPath
    structure::FractalStructure
    paths::Vector{Vector{Int64}}
end 

function idxes_to_dir(idx1::Int64, idx2::Int64, s::FractalStructure)::Int64
    # Returns the direction that connects two indexes.
    # direction = 1 => up
    # direction = 2 => right
    # direction = 3 => down
    # direction = 4 => left
    d = idx2 - idx1
    if d == 1
        return 2
    elseif d == -1
        return 4
    elseif d == s.width
        return 3
    elseif d == -s.width
        return 1
    end

    # If we are here, we have a cross-index move. Figure out which side each entry is on
    if idx1 ∈ s.sides[1] && idx2 ∈ s.sides[3]
        return 1
    elseif idx1 ∈ s.sides[2] && idx2 ∈ s.sides[4]
        return 2
    elseif idx1 ∈ s.sides[3] && idx2 ∈ s.sides[1]
        return 3
    elseif idx1 ∈ s.sides[4] && idx2 ∈ s.sides[2]
        return 4
    end
    
     # If we are here, then something unexpected happen. This is likely a
     # cross-index move
    error("Unexpected index-index difference!")
end

function idxes_to_available_outputs(idx1::Int64, idx2::Int64, s::FractalStructure)::Vector{Int64}
    d = idxes_to_dir(idx1, idx2, s)
    return s.sides[d]
end

# Transforms a boundary condition in a certain direction
function reflect_bc(direction::Int64, idx::Int64, s::FractalStructure)::Int64
    if direction == 1
        # Going up! Reflect by adding to width * (height - 1)
        return idx + (s.width * (s.height - 1))
    elseif direction == 2
        # Going right. Subtract (width - 1)
        return idx - (s.width - 1)
    elseif direction == 3
        # Going down. Add width and wrap
        return (idx + s.width)  % (s.width * s.height)
    elseif direction == 4
        # Going left. Add (width - 1)
        return idx + (s.width - 1)
    end
end

function generate_fractal_path(structure::FractalStructure)::FractalPath
    # Generate a fractal path of the desired size and with the specified number of levels.
    result::FractalPath = FractalPath(structure, [])
    n_tiles = structure.width * structure.height
    rng = MersenneTwister();

    # Generate the first level directly
    push!(result.paths, zeros(Int64, n_tiles))
    generate_path!(
        result.paths[1],
        structure.width, structure.height,
        [1], [(structure.width * structure.height)],
        rng
    )
    for level in 2:structure.n_levels
        # We need to iterate over level i-1 and generate paths as we go.
        # Create the large path structure
        push!(result.paths, zeros(Int64,(n_tiles)^level))
        generate_path!(
                  @view(result.paths[level][1:n_tiles]),
                  structure.width, structure.height,
                  [1,structure.width],
                  idxes_to_available_outputs(result.paths[level-1][1], result.paths[level-1][2],structure),
                  rng
        )
        # For the next N-2 entries, reflect the tile
        for i in 2:(length(result.paths[level-1]) - 1)
            generate_path!(
                @view(result.paths[level][(((i-1) * n_tiles) + 1):(i * n_tiles)]),
                structure.width, structure.height,
                [reflect_bc(idxes_to_dir(
                        result.paths[level-1][i-1],
                        result.paths[level-1][i],
                        structure),
                    result.paths[level][(i-1) * n_tiles],structure)],
                idxes_to_available_outputs(
                    result.paths[level-1][i],
                    result.paths[level-1][i+1],
                    structure),
                rng
            )
        end
        # Push the last subpath
        generate_path!(
            @view(result.paths[level][(end-n_tiles+1):end]),
            structure.width, structure.height,
            [reflect_bc(idxes_to_dir(
                    result.paths[level-1][end-1],
                    result.paths[level-1][end],
                    structure),
                result.paths[level][end-n_tiles],structure)],
            [(structure.width * structure.height)],
            rng
        )
    end
    return result
end


struct FractalViz
    level_offsets::Vector{Int64}
    jitter_magnitude::Vector{Float64}
    polymerase_variance::Vector{Float64}
    polymerase_base_rate::Float64
    n_chromosomes::Int64
    colors
end

function draw_fractal_path(path::FractalPath, viz::FractalViz, filename)
    # Generate jitter offsets
    jitter = [clamp.(randn(
        (path.structure.width * path.structure.height)^level,2) * viz.jitter_magnitude[level],
        -viz.jitter_magnitude[level], viz.jitter_magnitude[level])
        for level in 1:path.structure.n_levels]
    # Generate polymerase propensities
    rnap_propensity = [
        clamp.(1.0 .+ (randn((path.structure.width * path.structure.height)^level) * viz.polymerase_variance[level]),0.0, 5.0)
        for level in 1:path.structure.n_levels
    ]
    n_per_chromosome = ceil(Int64, ((path.structure.width * path.structure.height)^path.structure.n_levels) / viz.n_chromosomes)
    Drawing(2*path.structure.width^path.structure.n_levels, 2*path.structure.height^path.structure.n_levels, filename)
    setline(0.5)
    newpath()
    move(0,0)
    setcolor(viz.colors[1])
    polymerase_accum = []
    for i in 1:length(path.paths[end])
        if i % n_per_chromosome == 1
            # New chromosome!
            do_action(:stroke)
            setcolor(viz.colors[ceil(Int64, i / n_per_chromosome)])
            newpath()
        end
        indicies = [path.paths[level][
            ceil(Int64,i / (
                path.structure.width * 
                path.structure.height)^(
                    path.structure.n_levels - level
                ))] for level in 1:path.structure.n_levels]
        x_offsets = map(idx->idx_to_zero_x(path.structure.width,idx),indicies) .* viz.level_offsets + map(level->jitter[level][indicies[level],1], 1:path.structure.n_levels)
        y_offsets = map(idx->idx_to_zero_y(path.structure.width,idx),indicies) .* viz.level_offsets + map(level->jitter[level][indicies[level],2], 1:path.structure.n_levels)
        x_loc = sum(x_offsets)
        y_loc = sum(y_offsets)
        line(Point(x_loc, y_loc))

        polymerase_rate = viz.polymerase_base_rate * prod(map(level->rnap_propensity[level][indicies[level]], 1:path.structure.n_levels))
        if rand() < polymerase_rate
            push!(polymerase_accum, (x_loc,y_loc))
        end
    end
    do_action(:stroke)

    # Place polymerases
    gsave()
    for polymerase_loc in polymerase_accum
        setcolor(0.4,0.4,0.4,0.6)
        circle(polymerase_loc...,0.7,:fill)
        setcolor(0.4,0.4,0.4,0.9)
        setline(0.2)
        circle(polymerase_loc...,0.7,:stroke)
        setcolor(0.6, 0.6, 0.6, 1.0)
        setline(0.5)
        dx = randn() * 3
        dy = randn() * 3
        drawbezierpath(bezierfrompoints(
            Point(polymerase_loc...),
            Point(polymerase_loc[1] + (0.25 * dx) + randn() * 0.3, polymerase_loc[2] + (0.25 * dy)),
            Point(polymerase_loc[1] + (0.75 * dx) + randn() * 0.3, polymerase_loc[2] + (0.75 * dy)),
            Point(polymerase_loc[1] + dx, polymerase_loc[2] + dy)), :stroke, close=false)
    end
    grestore()

    finish()
end

# Precompile hints
generate_path(4,4,[1],[2], MersenneTwister());
end # module