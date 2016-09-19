# reed-solomon
Basic reed-solomon encoder/decoder

The base idea was that you could evade XOR key brute forces and similar by introducing errors into your Office documents with embedded executables or just leave out the embedded executable all together and then have a reed solomon decoder that itself was suitably small and polymorphic.

I promised myself I'd get around to finishing this, I had real life stuff catch on fire and I just haven't circled back. The assembly is highly sub-optimal and the overall implementation represents a rough sketch at best, but thats the general idea-- using reed solomon to evade signature based detection inclusive of exhaustive XOR key brute force attempts.
