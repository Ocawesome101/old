# SimpleAAF

SimpleAAF is a simpler version of [zenith391's AAF format](https://github.com/zenith391/Random-OC-Docs/blob/master/Audio/AAF.md). 


### Format

SimpleAAF uses simple text files to store its data, with each line in the following format. 

`FREQUENCY DURATION`

This does not lend itself to particularly good compression, but the files are very easy to parse. 


### Parsing

SimpleAAF files should be loaded, split into lines, and each line parsed as two words, each of which being converted into numbers and passed to `computer.beep`. 
