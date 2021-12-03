using Luxor
using ChromatinArt
using Colors

result = ChromatinArt.generate_fractal_path(ChromatinArt.Fractal(9,9,3))
viz = ChromatinArt.FractalViz(
    [95, 10, 1],
    8,
    ["#66c2a5","#fc8d62","#8da0cb","#e78ac3","#a6d854","#ffd92f","#e5c494","#b3b3b3"],
    [3, 0.8, 0.3]
)
ChromatinArt.draw_fractal_path(result, viz, "test.svg")