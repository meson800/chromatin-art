using ChromatinArt
using Luxor
using Colors

result = ChromatinArt.generate_fractal_path(ChromatinArt.Fractal(7,7,4))
viz = ChromatinArt.FractalViz(
    [425,60, 8, 1],
    [8, 3, 1, 0.3],
    [0.5, 0.15, 0.1, 0.0],
    0.01,
    8,
    ["#66c2a5","#fc8d62","#8da0cb","#e78ac3","#a6d854","#ffd92f","#e5c494","#fb8072"],
)
ChromatinArt.draw_fractal_path(result, viz, "test.pdf")
ChromatinArt.draw_fractal_path(result, viz, "test.svg")