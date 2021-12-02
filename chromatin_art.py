import numpy as np

def generate_path(width: int, height: int, inputs:np.ndarray, outputs:np.ndarray) -> np.ndarray:
    """
    Generates a contiguous path from an input to an output, where every cell in the given
    matrix is visited once by the contiguous path.

    Inputs and outputs are given using the same numbering scheme as the returned path. Tile 0
    is the upper left corner, and tiles proceed left-to-right, top-to-bottom.

    Arguments:
    ----------
    width: the width of the region.
    height: the height of the region.
    inputs: the list of available starting locations. One is randomly chosen.
    outputs: the list of available ending locations.

    Returns:
    --------
    A (width * height,1) ndarray with the indicies of the path tiles visited.
    """
    n_tiles = width * height
    stack = -np.ones((n_tiles,1))
    result = -np.ones((n_tiles,1))
    
    # setup iterative BFS
    return result

if __name__ == '__main__':
    pass
