module ChromatinArt

using Random
using Luxor

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
function hamiltonian_mc_step!(path::Vector{Int64}, width::Int64, height::Int64)
    if rand(1:2) == 1
        # Reverse the list before we start
        reverse!(path)
    end
    # Try to step away from the head
    dir = rand(1:4)
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
    reverse!(path, 1, indexin(zero_xy_to_idx(width,x,y),path)[1] - 1)
end

function generate_path(width::Int64, height::Int64, inputs::Vector{Int64}, outputs::Vector{Int64})::Vector{Int64}
    n_tiles = width * height
    # Init a Hamiltonian path
    result = Vector{Int64}(1:n_tiles)
    # Reverse every other row to get a Hamiltonian starting path
    for row in 2:2:height
        reverse!(result, 1 + (row - 1) * width, row * width)
    end

    # Initialize by doing some random iterations
    for i in 1:(n_tiles * 10)
        hamiltonian_mc_step!(result, width, height)
    end

    while result[1] ∉ inputs  || result[end] ∉ outputs 
        hamiltonian_mc_step!(result, width, height)
    end
    return result
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

    # Generate the first level directly
    push!(result.paths, generate_path(
        structure.width, structure.height,
        [1], [(structure.width * structure.height)]
    ))
    for level in 2:structure.n_levels
        # TODO: for levels > 2, you need to account for the idx swaps once you go every (width * height) tiles,
        # in order to do the proper "wrap-around boundary conditions"
        # We need to iterate over level i-1 and generate paths as we go.
        # We can vcat them all together as we go along.
        subpaths = []
        # Create the first subpath
        push!(subpaths, generate_path(
                  structure.width, structure.height,
                  [1,structure.width],
                  idxes_to_available_outputs(result.paths[level-1][1], result.paths[level-1][2],structure)
        ))
        # For the next N-2 entries, reflect the tile
        for i in 2:(length(result.paths[level-1]) - 1)
            push!(subpaths, generate_path(
                structure.width, structure.height,
                [reflect_bc(idxes_to_dir(
                        result.paths[level-1][i-1],
                        result.paths[level-1][i],
                        structure),
                    subpaths[end][end],structure)],
                idxes_to_available_outputs(
                    result.paths[level-1][i],
                    result.paths[level-1][i+1],
                    structure)
            ))
        end
        # Push the last subpath
        push!(subpaths, generate_path(
            structure.width, structure.height,
            [reflect_bc(idxes_to_dir(
                    result.paths[level-1][end-1],
                    result.paths[level-1][end],
                    structure),
                subpaths[end][end],structure)],
            [(structure.width * structure.height)]
        ))
        # Concat at get out!
        push!(result.paths,vcat(subpaths...))
    end
    return result
end


struct FractalViz
    level_offsets::Vector{Int64}
end

function draw_fractal_path(path::FractalPath, viz::FractalViz, filename)
    Drawing("Letter", filename)
    newpath()
    move(0,0)
    sethue("black")
    for i in 1:length(path.paths[end])
        indicies = [path.paths[level][
            ceil(Int64,i / (
                path.structure.width * 
                path.structure.height)^(
                    path.structure.n_levels - level
                ))] for level in 1:path.structure.n_levels]
        x_offsets = map(idx->idx_to_zero_x(path.structure.width,idx),indicies) .* viz.level_offsets
        y_offsets = map(idx->idx_to_zero_y(path.structure.width,idx),indicies) .* viz.level_offsets
        line(Point(sum(x_offsets), sum(y_offsets)))
        print(".")
    end
    do_action(:stroke)
    finish()
end

# Precompile hints
generate_path(4,4,[1],[2]);
end # module