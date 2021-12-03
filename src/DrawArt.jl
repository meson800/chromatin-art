using Luxor
using ChromatinArt

result = ChromatinArt.generate_fractal_path(ChromatinArt.FractalStructure(5,5,2))
ChromatinArt.draw_fractal_path(result, ChromatinArt.FractalViz([70,10]), "test.svg")