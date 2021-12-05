using ChromatinArt
using Luxor
using Colors

result = ChromatinArt.generate_fractal_path(ChromatinArt.Fractal(7,7,4))
viz = ChromatinArt.FractalViz(
    [425,60, 8, 1], [7.5, 2.6, 0.8, 0.17], # [Offset per level], [jitter amount per level]
    [0.5, 0.15, 0.1, 0.0], 0.01,    # [RNAP activity jitter per level], base RNAP activity
    0.8, 3.0,                       # swirl strength, swirl dropoff
    8,["#66c2a5","#fc8d62","#8da0cb","#e78ac3","#a6d854","#ffd92f","#e5c494","#fb8072"], # number of chromosomes, chromosome colors
    false # skip loops
)
ChromatinArt.draw_fractal_path(result, viz, "test.pdf")

# Make a clean version
clean_result = ChromatinArt.generate_fractal_path(ChromatinArt.Fractal(9,9,3))
ChromatinArt.draw_fractal_path(clean_result, ChromatinArt.FractalViz(
    [81,9,1], [0.0,0.0,0.0],
    [0.0,0.0,0.0], 0.0,
    0.0,0.0, 
    8,["#66c2a5","#fc8d62","#8da0cb","#e78ac3","#a6d854","#ffd92f","#e5c494","#fb8072"],
    true), "clean.pdf")