//Display results
var _string = "";
_string += "Ngram fuzzy string matching\n";
_string += "Juju Adams 2023-11-19\n";
_string += "\n";
_string += "Type to search for a word\n";
_string += "Input = \"" + ngram.GetString() + "\"\n";
_string += "\n";
_string += "Results = \"" + string(ngram.GetWordArray()) + "\"\n";
_string += "Strengths = \"" + string(ngram.GetStrengthArray()) + "\"\n";
draw_text(10, 10, _string);