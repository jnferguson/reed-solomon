# reed-solomon
Basic reed-solomon encoder/decoder

The base idea was that you could evade XOR key brute forces and similar by introducing errors into your Office documents with embedded executables or just leave out the embedded executable all together and then have a reed solomon decoder that itself was suitably small and polymorphic.

I promised myself I'd get around to finishing this, I had real life stuff catch on fire and I just haven't circled back. The assembly is highly sub-optimal and the overall implementation represents a rough sketch at best, but thats the general idea-- using reed solomon to evade signature based detection inclusive of exhaustive XOR key brute force attempts.

Symbol size and similar was introduced with the focus of eventually being shellcode, so some areas are make trade offs in code size in exchange for smaller lookup tables and similar constraints that would be expected when implementing a generic payload for an exploit (id est no giant allocations on the stack and similar). It was originally written to be relocatable but it looks like most of those revisions are in a different version of the code.
