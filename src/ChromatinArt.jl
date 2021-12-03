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

    # Initalize by doing some random iterations
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
end

struct FractalPath
    structure::FractalStructure
    paths::Vector{Vector{Int64}}
end 

function idxes_to_dir(idx1::Int64, idx2::Int64, width::Int64)::Int64
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
    elseif d == width
        return 3
    elseif d == -width
        return 1
    end
    error("Unexpected index-index difference!")
end

function idxes_to_available_outputs(idx1::Int64, idx2::Int64, s::FractalStructure)::Vector{Int64}
    d = idxes_to_dir(idx1, idx2, s.width)
    if d == 1
        return [1,s.width]
    elseif d == 2
        return [s.width,(s.width * s.height)]
    elseif d == 3
        return [(s.width * (s.height - 1) + 1),(s.width * s.height)]
    elseif d == 4
        return [1,(s.width * (s.height - 1) + 1)]
    end
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

# Recursively generates a fractal level
# starting and ending at specific locations.
# This returns the final output source used.
function generate_fractal_level!(fractal_path::FractalPath, incoming::Int64, outgoing::Int64, target_level::Int64, s::FractalStructure)::Int64
    # Check which level we are on.
    if fractal_path.level_of_detail < target_level - 1
        # Recurse inward, passing along the return value
        curried_retval = generate_fractal_level!(fractal_path.subpaths[1], incoming, outgoing, target_level, s)
        for subpath in fractal_path.subpaths[2:end]
            curried_retval = generate_fractal_level!(subpath, incoming, outgoing, target_level, s)
        end
        return curried_retval
    elseif fractal_path.level_of_detail == target_level - 1
        # Time to create new levels!

    end
    
    # Follow the path around the fractal! Start by handling the initial case, where we have to create the first
    # fractal at level (i+1)

    # This fractal connects the requested incoming idx to a random outgoing on the outgoing side.
    push!(fractal_path.subpaths, FractalPath(
        generate_path(s.width, s.height,
        [incoming], idxes_to_available_outputs(fractal_path.path[1], fractal_path.path[2], s)),
        [], fractal_path.level_of_detail + 1))
    # Recursively generate 
    # For the next N - 2 entries, propogate the incoming/outgoing to match it up

    # For the last entry, use the desired outgoing entry
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
                        structure.width),
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
                    structure.width),
                subpaths[end][end],structure)],
            [(structure.width * structure.height)]
        ))
        # Concat at get out!
        print(subpaths)
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
