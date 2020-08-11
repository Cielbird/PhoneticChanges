using Pkg

Pkg.add("ArgParse")
using ArgParse


"""
    SoundChange(before::Regex, after::SubstitutionString)

A type that stores sound change information. To be used with `replace` and sdf
[`parseModifierTags`](@ref)
"""
struct SoundChange 
    before::Regex
    after::SubstitutionString
end

"""
Manners of articulation
"""
const consMannersOfArt = [
    "PLOS",
    "NASAL",
    "TRILL",
    "TAP",
    "FRIC",
    "LATFRIC",
    "APPROX",
    "LATAPPROX"
]
"""
Places of articulation
"""
const consPlacesOfArt = [
    "BILAB",
    "LABDENT",
    "DENT",
    "ALV",
    "POSTALV",
    "RETRO",
    "PALAT",
    "VELAR",
    "UVUL",
    "PHARYN",
    "GLOT"
]
"""
Voiceness of consonants
"""
const consVoice = [
    "UNVOICED",
    "VOICED"
]
"""
Height of vowels
"""
const vowelHeight = [
    "CLOSED",
    "NEARCLOSED",
    "MIDCLOSED",
    "MID",
    "MIDOPEN",
    "NEAROPEN",
    "OPEN"
]
"""
Frontedness of vowels
"""
const vowelPosition = [
    "FRONT",
    "NEARFRONT",
    "CENTRAL",
    "NEARBACK",
    "BACK"
]
"""
Roundness of vowels
"""
const vowelRoundedness = [
    "UNROUNDED",
    "ROUNDED"
]

#indices are as folows: [manner of articulation, place of articulation, voice]
const consonants = cat(
[   'p'     nothing 't'     't'     't'     'ʈ'     'c'     'k'     'q'     nothing 'ʔ';
    nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing;
    nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing;
    nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing;
    'ɸ'     'f'     'θ'     's'     'ʃ'     'ʂ'     'ç'     'x'     'χ'     'ħ'     'h'    ;
    nothing nothing 'ɬ'     'ɬ'     'ɬ'     nothing nothing nothing nothing nothing nothing;
    nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing;
    nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing],

[   'b'     nothing 'd'     'd'     'd'     'ɖ'     'ɟ'     'g'     'ɢ'     nothing nothing;
    'm'     'ɱ'     'n'     'n'     'n'     'ɳ'     'ɲ'     'ŋ'     'ɴ'     nothing nothing;
    'ʙ'     nothing 'r'     'r'     'r'     nothing nothing nothing 'ʀ'     nothing nothing;
    nothing 'ⱱ'     'ɾ'     'ɾ'     'ɾ'     'ɽ'     nothing nothing nothing nothing nothing;
    'β'     'v'     'ð'     'z'     'ʒ'     'ʐ'     'ʝ'     'ɣ'     'ʁ'     'ʕ'     'ɦ'    ;
    nothing nothing 'ɮ'     'ɮ'     'ɮ'     nothing nothing nothing nothing nothing nothing;
    nothing 'ʋ'     'ɹ'     'ɹ'     'ɹ'     'ɻ'     'j'     'ɰ'     nothing nothing nothing;
    nothing nothing 'l'     'l'     'l'     'ɭ'     'ʎ'     'ʟ'     nothing nothing nothing],  dims = 3)

#indeces are as folows: [openness, position, roundness]
const vowels = cat(
[   'i'     nothing 'ɨ'     nothing 'ɯ' ;
    nothing 'ɪ'     nothing 'ʊ'     nothing;
    'e'     nothing 'ɘ'     nothing 'ɤ' ;
    nothing nothing 'ə'     nothing nothing;
    'ɛ'     nothing 'ɜ'     nothing 'ʌ' ;
    'æ'     nothing 'ɐ'     nothing nothing;
    'a'     nothing nothing nothing 'ɑ' ], 

[   'y'     nothing 'ʉ'     nothing 'u' ;
    nothing 'ʏ'     nothing 'ʊ'     nothing;
    'ø'     nothing 'ɵ'     nothing 'o' ;
    nothing nothing nothing nothing nothing;
    'œ'     nothing 'ɞ'     nothing 'ɔ' ;
    nothing nothing nothing nothing nothing;
    'ɶ'     nothing nothing nothing 'ɒ' ], dims = 3)



function main(args)

    s = ArgParseSettings("PhoneticChanges.jl:")

    @add_arg_table! s begin
        "inputFile"
        help = "file path for the input words"
        required = true
        "outputFile"
        help = "file path for the output words"
        required = true
        "changeFile"
        help = "file path for the word changes"
        required = true
    end

    parsed_args = parse_args(args, s)
    

    #"C:\\Users\\guilh\\OneDrive\\Desktop\\ConlangingTool\\sound_changes.txt"
    #"C:\\Users\\guilh\\OneDrive\\Desktop\\ConlangingTool\\input.txt"
    output = applySoundChanges(parsed_args["changeFile"], parsed_args["inputFile"])
    open(parsed_args["outputFile"], "w") do f
        write(f, output)
    end
    print("Phonetic changes applied successfully. Output is at: "*parsed_args["outputFile"])
end


"""
    getConsGroupRX(tagsString::String)

Returns all the ipa's plumonic consonants that fit the `tagsString` in a 
bracketed string. Usefull for regex expresions.

`tagsString` must begin with `C`, then may be folowed by any amount of 
comma-seperated tags between `/ /`.
see [`consMannersOfArt`](@ref), [`consPlacesOfArt`](@ref), [`consVoice`](@ref).
Whitespace is ignored.

# Examples
```julia-repl
julia> getConsGroupRX("C/VELAR/")
"[kgŋxɣɰʟ]"

julia> getConsGroupRX("C")
"[pɸftθɬt...]"

julia> getConsGroupRX("C/ALV,VOICED,PLOS/")
"[d]"
```
"""
function getConsGroupRX(tagsString) 
    m = match(r"\/([^\/]+)\/+", tagsString)
    matchingConsonants = []
    if m == nothing
        for cons in consonants
            if cons != nothing
                push!(matchingConsonants, cons)
            end
        end
    else
        tags = split(m.captures[1], r"\s*,\s*", limit = 0, keepempty = false)
        for moa in 1:size(consonants)[1]
            for poa in 1:size(consonants)[2]
                for v in 1:size(consonants)[3]
                    cons = consonants[moa, poa, v]
                    if cons != nothing && !(cons in matchingConsonants)
                        consMatchesTags = true
                        for tag in tags
                            possibleTags = [tag]
                            if tag == "OBST"
                                possibleTags = ["PLOS", "TRILL", "TAP", "TRIC", "LATFRIC"]
                            elseif tag == "SONOR"
                                possibleTags = ["NASAL", "APPROX", "LATAPPROX"]
                            end
                            matchesOnePossibleTag = false
                            for possibleTag in possibleTags
                                if possibleTag == consMannersOfArt[moa] || possibleTag == consPlacesOfArt[poa] || possibleTag == consVoice[v]
                                    matchesOnePossibleTag = true
                                    break
                                end
                            end
                            if !matchesOnePossibleTag
                                consMatchesTags = false
                                break
                            end
                        end
                        if consMatchesTags
                            push!(matchingConsonants, cons)
                        end
                    end
                end
            end
        end
    end

    if length(matchingConsonants) == 0
        error("Tag does not exist")
    end

    result = "["
    for matchingConsonant in matchingConsonants
        result *= string(matchingConsonant)
    end
    result *= "]"
    return result
end

"""
    getVowelGroupRX(tagsString::String)

Returns all the ipa's vowels that fit the `tagsString` in a bracketed string. 
Usefull for regex expresions.

`tagsString` must begin with `V`, then may be folowed by any amount of 
comma-seperated tags between `/ /`.
see [`vowelHeight`](@ref), [`vowelPosition`](@ref), [`vowelRoundedness`](@ref).
Whitespace is ignored.

# Examples
```julia-repl
julia> getVowelGroupRX("V/ROUNDED/")
"[yʉuʏʊøɵoœɞɔɶɒ]"

julia> getVowelGroupRX("V")
"[ieɛæaɪɨɘ...]"

julia> getVowelGroupRX("C/ROUNDED,FRONT,CLOSED/")
"[d]"
```
"""
function getVowelGroupRX(tagsString) 
    m = match(r"\/([^\/]+)\/+", tagsString)
    matchingVowels = []
    if m == nothing
        for vowel in vowels
            if vowel != nothing
                push!(matchingVowels, vowel)
            end
        end
    else
        tags = split(m.captures[1], r"\s*,\s*", limit = 0, keepempty = false)
        for height in 1:size(vowels)[1]
            for pos in 1:size(vowels)[2]
                for r in 1:size(vowels)[3]
                    vowel = vowels[height, pos, r]
                    if vowel != nothing && !(vowel in matchingVowels)
                        vowelMatchesTags = true
                        for tag in tags
                            possibleTags = [tag]
                            if tag == "MIDTOCLOSED"
                                possibleTags = ["MID", "MIDCLOSED", "NEARCLOSED", "CLOSED"]
                            elseif tag == "MIDTOOPEN"
                                possibleTags = ["MID", "MIDOPEN", "NEAROPEN", "OPEN"]
                            end
                            matchesOnePossibleTag = false
                            for possibleTag in possibleTags
                                if possibleTag == vowelHeight[height] || possibleTag == vowelPosition[pos] || possibleTag == vowelRoundedness[r]
                                    matchesOnePossibleTag = true
                                    break
                                end
                            end
                            if !matchesOnePossibleTag
                                vowelMatchesTags = false
                                break
                            end
                        end
                        if vowelMatchesTags
                            push!(matchingVowels, vowel)
                        end
                    end
                end
            end
        end
    end

    if length(matchingVowels) == 0
        error("Tag does not exist")
    end

    result = "["
    for matchingVowel in matchingVowels
        result *= string(matchingVowel)
    end
    result *= "]"
    return result
end

"""
    modifySymbol(original::Char, modifierString::String)

Returns a character `original` modified by the tags `modifiers`. 
whitespace is ignored.
for vowel modifiers, see [`vowelHeight`](@ref), [`vowelPosition`](@ref), 
    and [`vowelRoundedness`](@ref). 
for consonant modifiers, see [`consMannersOfArt`](@ref), 
    [`consPlacesOfArt`](@ref), and [`consVoice`](@ref). 

# Examples
```julia-repl
julia> modifySymbol('i', "/ROUNDED/")
'y': ASCII/Unicode...
```
"""
function modifySymbol(original::Char, modifierString::String)
    modifiers = split(modifierString, r"\s*,\s*", limit = 0, keepempty = false)
    consIndices = findfirst(isequal(original), consonants)
    if consIndices != nothing
        #consonant
        for mod in modifiers
            moaIndex = findfirst(isequal(mod), consMannersOfArt)
            if moaIndex != nothing
                consIndices = CartesianIndex((moaIndex, consIndices.I[2], consIndices.I[3]))
                continue
            end
            poaIndex = findfirst(isequal(mod), consPlacesOfArt)
            if poaIndex != nothing
                consIndices = CartesianIndex((consIndices.I[1], poaIndex, consIndices.I[3]))
                continue
            end
            vIndex = findfirst(isequal(mod), consVoice)
            if vIndex != nothing
                consIndices = CartesianIndex((consIndices.I[1], consIndices.I[2], vIndex))
                continue
            end
        end
        return consonants[consIndices]
    end
    
    vowelIndices = findfirst(isequal(original), vowels)
    if vowelIndices != nothing
        #vowel
        for mod in modifiers
            heightIndex = findfirst(isequal(mod), vowelHeight)
            if heightIndex != nothing
                vowelIndices = CartesianIndex((heightIndex, vowelIndices.I[2], vowelIndices.I[3]))
                continue
            end
            posIndex = findfirst(isequal(mod), vowelPosition)
            if posIndex != nothing
                vowelIndices = CartesianIndex((vowelIndices.I[1], posIndex, vowelIndices.I[3]))
                continue
            end
            rIndex = findfirst(isequal(mod), vowelRoundedness)
            if rIndex != nothing
                vowelIndices = CartesianIndex((vowelIndices.I[1], vowelIndices.I[2], rIndex))
                continue
            end
        end
        return vowels[vowelIndices]
    end
    error("Tag does not exits")
end

function Base.show(io::IO, obj::SoundChange)
    output = string(obj.before) * " -> " * string(obj.after)
    print(io, output)
end

"""
    SoundChange(text::AbstractString)

reads `text` and constructs a SoundChange based off of it. 
"""
function SoundChange(text::AbstractString)
    text = replace(text, r"\s" => "")
    text = replace(text, r"([1-9])" => s"\\\1")

    if text == ""
        return nothing
    end

    splitString = split(text, ">")
    length(splitString)==2 || error("Can only have one greater sign per line! Text: $text")
    
    #convert any consonant or vowel letters to coresponding regex expresions
    for m in eachmatch(r"C(?:\/[^\/]*\/)?(?=[^\/]*(?:\/[^\/]*\/[^\/]*)*$)", splitString[1])
        match = Regex(m.match*"(?=[^/]|\$)") #so that the V in V/ROUNDED/ isnt caught|
        splitString[1] = replace(splitString[1], match => getConsGroupRX(m.match))
    end
    for m in eachmatch(r"V(?:\/[^\/]*\/)?(?=[^\/]*(?:\/[^\/]*\/[^\/]*)*$)", splitString[1])
        match = Regex(m.match*"(?=[^/]|\$)") #so that the V in V/ROUNDED/ isnt caught|
        splitString[1] = replace(splitString[1], match => getVowelGroupRX(m.match))
    end

    before = Regex(splitString[1])
    after = SubstitutionString(string(splitString[2]))
    return SoundChange(before,after)
end

"""
    parseModifierTags(original::String)

Applies all of the modifier tags next to characters in `original` and 
returns the final string

"""
function parseModifierTags(original::String)
    for modifiedSymbol in eachmatch(r"(.)\/([^\/]*)\/(?=[^\/]*(?:\/[^\/]*\/[^\/]*)*$)", original)
        original = replace(original, modifiedSymbol.match => modifySymbol(modifiedSymbol.captures[1][1], string(modifiedSymbol.captures[2])))
    end
    return original

end

"""
    applySoundChanges(change::SoundChange, original::String)

Applies the sound change `change` to `original` and returns the final string
"""
function applySoundChanges(change::SoundChange, original::String)
    original = replace(original, change.before => change.after)
    original = parseModifierTags(original)
    return original
end

"""
    applySoundChanges(changes::Vector{SoundChange}, original::String)

Applies all of the sound changes `changes` to `original` and 
returns the final string
"""
function applySoundChanges(changes::Vector{SoundChange}, original::String)
    for c in changes
        new = applySoundChanges(c, original)
        if new != original
            original = new
        end
    end
    return original
end

"""
    applySoundChanges(changesFile::String, originalFile::String)

Applies all of the sound change strings `changeStrings` to all 
the `originalStrings` and returns the final string with all the modified words
"""
function applySoundChanges(changesFile::String, originalFile::String)
    changeStrings = readlines(changesFile, keep=false)
    originalStrings = readlines(originalFile, keep=false)

    soundChanges = SoundChange[]

    for line in changeStrings
        newSoundChange = SoundChange(line)
        if isnothing(newSoundChange)
            continue
        else
            push!(soundChanges, newSoundChange)
        end
    end
    
    outputString = ""
    for original in originalStrings
        if original != ""
            original = applySoundChanges(soundChanges, original)
            outputString *= original*"\n"
        end
    end

    return outputString
end

main(ARGS)