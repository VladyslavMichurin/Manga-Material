# Explanation
This is a material that aims to make 3d objects look as if they were drawn in manga style. The shader uses lambertian diffuse for light and divides it in 3 sections: highlights, base color and shadows. Each section can be remaped to a specific color and you can regulate it's size. For shadows you can choose a texture that will be applied to that region, it rotates based on light direction and has several modes to determine how it should do it(you can change mode in shader). The outlines are made using inverted hull method and you can use a noise texture to make them more jagged.

# Gojo model  
With normal map for clothes
![gojo rotates](./Examples/Gojo-rotates(with-normal-map).gif)
Without normal map for clothes
![gojo rotates](./Examples/Gojo-rotates(without-normal-map).gif)


