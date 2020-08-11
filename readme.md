PhoneticChanges.jl
==================

Purpose
-------
PhoneticChanges.jl is an automated tool to apply series of linguistic 
sound changes to words using IPA.

Usefull for conlanging.

Instalation
-----------
PhoneticChanges uses julia, so 
[install julia first.](https://julialang.org/downloads/)


Clone the repository, or download the zip file.

    git clone https://github.com/Cielbird/PhoneticChanges.git

or

- Code > Download ZIP

Use
---

PhoneticChanges.jl uses three `.txt` files to work. The input file, 
the changes file, and the output file.

    julia PhoneticChanges.jl [inputFile] [outputFile] [changesFile]


Input file
----------

The input file should contain each word you intend to modify on each line. 
Empty lines are ignored. Words should be writen in 
[IPA](https://www.ipachart.com/).

Output file
----------

The output file does not need to be created before calling PhoneticChanges.jl.

Changes file
------------
The changes file should contain the list of shound changes the words should go 
through. Whitespace and empty lines are ignored.

Each change is structured like so:

    [Items to look for] > [What to replace it with]

So a simple sound change of `b` to `v` would be writen as:

    b > v

To write more general and vague expressions, you can use `C` (for consonants) 
and `V` (cor vowels) to match groups of IPA symbols. 
See [vowel tags](#vowel-tags) and [consonant tags](#consonant-tags)

So to match all consonants, and replace them with `ʂ`:

    C > ʂ

Or to replace vowels with `i`:

    V > i

### Tags

Where PhoneticChanges is really usefull is with *tags*. To specify certain types
of consonants or vowels, add *tags* between two slashes (`/`) after a `C` or 
a `V`. Multiple tags can be added, seperated by commas. The tags are all the 
requirements a symbol must fit to be matched.
Below are a list of tags available:

So `C/UVUL/` will match all uvular consonants, and `V/OPEN, FRONT/` will 
match all open fronted vowels (`a` and  `ɶ`)

Using these tags, we can make much more usefull statements like:

All unvoiced consonants are lost (replaced with nothing)

    C/UNVOICED/ > 

*an empty right side will simply reaplace all matches with nothing, 
deleting them.*


### Captures

To reuse any symbol we match, we need to *capture*(save, or remember) it.
To do this, we surround it with parenthases `( )`.

    (V)

Once we've captured a character or set of characters, we can reference that 
captured group with a coresponding number 
(in this case `1`, since we only have one capture).

    (V) > 1
*this will not apprear to change anything, as you are replacing 
what you captured, with what you captured.*

Here, we capture the vowels on both side of an unvoiced consonant, 
and reference them, leaving out the consonant. This effectively deletes all 
unvoiced consonants between vowels.

    (V) C/UNVOICED/ (V) > 1 2

### Modifiers

Adding tags between `/` after referenced groups like so: `1/VOICED/` 
or `3/UVUL, ROUNDED/` will modify the preceeding character to fit the tags.

This will replace all consonants preceding voiced consonants with their 
voiced equivilents. (`d` with replace `t`, `z` will replace `s`...)

    (C) (C/VOICED/) > 1/VOICED/ 2




## Consonant Tags
| Manner of articulation  | Place of articulation   | Voice    |
|-------------------------|-------------------------|----------|
| PLOS                    | BILAB                   | UNVOICED |
| NASAL                   | LABDENT                 | VOICED   |
| TRILL                   | DENT
| TAP                     | ALV
| FRIC                    | POSTALV
| LATFRIC                 | RETRO
| APPROX                  | PALAT
| LATAPPROX               | VELAR
|                         | UVUL
|                         | PHARYN
|                         | GLOT

## Vowel Tags
| Height     | Frontedness/Position | Voice    |
|------------|----------------------|----------|
| CLOSED     | FRONT                | UNROUNDED |
| NEARCLOSED | NEARFRONT            | ROUNDED   |
| MIDCLOSED  | CENTRAL
| MID        | NEARBACK
| MIDOPEN    | BACK
| NEAROPEN
| OPEN