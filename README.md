## Chromatin-Art

### A package for rendering chromatin pictures.
See DrawArt.jl for usage. It is straightforward to make hierarchical chromatin art diagrams:
```
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
```

By changing the filename, you can export PNG, PDF, and SVG versions of the art.

### License
This is licensed under the MIT license.