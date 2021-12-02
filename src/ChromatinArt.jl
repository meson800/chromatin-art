module ChromatinArt

using Random

greet() = print("Hello World!")

function generate_path(width::Int64, height::Int64, inputs::Vector{Int64}, outputs::Vector{Int64})::Vector{Int64}
    n_tiles = width * height
    pathlen = 1
    stack = zeros(Int64,n_tiles,2)
    # Fill directions with (1,2,3,4), generating it randomly
    directions = hcat([randperm(4) for _ in 1:n_tiles]...) # 4 x n_tiles array
    bitmask = zeros(Bool,n_tiles)

    # Setup BFS
    stack[1,1] = rand(inputs)
    stack[1,2] = 1
    bitmask[stack[1,1]] = true

    # Iterate until we have a full-length path stopping on one of the valid outputs
    while pathlen != n_tiles || stack[pathlen,1] ∉ outputs
        # Check if we have exhausted all options of directions to go
        if stack[pathlen,2] == 5
            if pathlen == 1
                @error "Failed to do DFS to get a solution :("
            end
            # Otherwise, reset bitmask and pathlen
            bitmask[stack[pathlen,1]] = false
            pathlen = pathlen - 1
            continue
        end

        # Try to iterate into a child based on our location. Do the internal
        # conversion to zero-indexed and back to one-indexed.
        current_idx = stack[pathlen,1]
        current_x = (current_idx - 1) % width
        current_y = trunc(Int64, (current_idx - 1) / width)
        proposed_direction = directions[stack[pathlen,2],current_idx]
        stack[pathlen,2] += 1
        if     proposed_direction == 1
            proposed_x = current_x + 1
            proposed_y = current_y
        elseif proposed_direction == 2
            proposed_x = current_x - 1
            proposed_y = current_y
        elseif proposed_direction == 3
            proposed_x = current_x
            proposed_y = current_y + 1
        elseif proposed_direction == 4
            proposed_x = current_x
            proposed_y = current_y - 1
        end
        proposed_idx = proposed_x + proposed_y * width + 1

        # Is this step possible? Skip if the piece is already occupied
        # or if the proposed region exits our desired region
        if proposed_x < 0 || proposed_x >= width ||
           proposed_y < 0 || proposed_y >= height ||
           bitmask[proposed_idx]
           continue
        end
        # Step into this region
        pathlen = pathlen + 1
        bitmask[proposed_idx] = true
        stack[pathlen,1] = proposed_idx
        stack[pathlen,2] = 1
    end
    return stack[:,1]
end

struct FractalPath
    path::Vector{Int64}
    subpaths::Vector{FractalPath}
    level_of_detail::Int
end

function generate_fractal_path(width::Int64, height::Int64, n_levels::Int64)::Vector{FractalPath}
    # Generate a fractal path of the desired size and with the specified number of levels.
    result::Vector{FractalPath} = []

    # Generate the first level directly
    push!(result,
          FractalPath(
              generate_path(width,height,Vector(1:(width*height)),Vector(1:(width*height))),
              [],
              1))
    for level in 2:n_levels
        # We need to generate (width * height)^(level - 1) individual levels now.
    end

    return result
end

# Precompile hints
generate_path(4,4,[1],[2]);
end # module
