# reed-solomon
Basic reed-solomon encoder/decoder

This was written and intended as a first pass at reed-solomon related shellcode, it needs to be rewritten for size and similar and a polymorphic encoder is necessary. The idea is meant to be coupled together with the huffman coding tables, which itself needs to be paired down into assembly and rewritten (the C++ was just to teach myself huffman coding).

The premise is meant to avoid detection and defensive counter-measures that as far as I know are not deployed today, but will be eventually at some point in the future. If you don't drop a file and you use a polymorphic reed-solomon decoder, then your shellcode can take on arbitrary entropic properties and never have any specific static signature because you can arbitrarily introduce errors.

This thought process effectively recursively turns defense into a matter that must entail off-line processing, which causes an increase in expenditures thereby tying the matter back to the tangible.

Symbol size and similar was introduced with the focus of eventually being shellcode, so some areas are make trade offs in code size in exchange for smaller lookup tables and similar constraints that would be expected when implementing a generic payload for an exploit (id est no giant allocations on the stack and similar). It was originally written to be relocatable but it looks like most of those revisions are in a different version of the code.

