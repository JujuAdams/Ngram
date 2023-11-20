/// Ngram([maxSubstringLength=4]) constructor
/// 
/// Creates an Ngram strength search handler. The returned struct contains the following methods:
/// 
/// .SetLexiconArray(array)
///   Sets the dictionary to fuzzy match against. This function is pretty slow so try to call it
///   at an opportune time.
/// 
/// .SetString(string)
///   Sets the search string. Changing the search string will restart the search.
/// 
/// .GetString()
///   Returns the string being used to search.
/// 
/// .GetWordArray()
///   Returns an array of words that have been fuzzy matched to the input string. The maximum
///   number of results is set by .SetMaxResults(). The array is sorted in order of strength such
///   that the word in array position 0 is closest to the input string.
/// 
/// .SetMaxResults(value)
///   Sets the maximum number of results to return. Defaults to 10
/// 
/// .GetMaxResults()
///   Returns the maximum number of results.
/// 
/// .GetResultArray()
///   Returns an array of results. Each element in the array is a struct that contains two
///   variables: .word is the string from the dictionary that has been matched, .strength is the
///   strength of the match to the input string. This function should be used to return detailed
///   information about the found words. It is normally preferable to use the simpler
///   .GetWordArray() method above.

function Ngram(_maxSubstringLength = 4) constructor
{
    __maxSubstringLength = _maxSubstringLength;
    __exactDict = {};
    __ngramDict = {};
    
    __string     = "";
    __maxResults = 10;
    
    __wordArray = [];
    
    __Clear();
    
    static __Clear = function()
    {
        __wordArrayDirty = true;
        array_resize(__wordArray, 0);
        __resultArray = [];
    }
    
    static SetLexiconArray = function(_array)
    {
        __Clear();
        
        __exactDict = {};
        __ngramDict = {};
        
        var _funcPush = function(_substring, _string)
        {
            var _array = __ngramDict[$ _substring];
            if (not is_array(_array))
            {
                _array = [_string];
                __ngramDict[$ _substring] = _array;
            }
            else
            {
                array_push(_array, _string);
            }
        }
        
        var _i = 0;
        repeat(array_length(_array))
        {
            var _sourceString = _array[_i];
            
            __exactDict[$ _sourceString] = true;
            
            var _sourceLength = string_length(_sourceString);
            
            var _string = _sourceString;
            repeat(__maxSubstringLength-1)
            {
                _string = " " + _string + " ";
            }
            
            var _substringLength = 1;
            repeat(min(_sourceLength, __maxSubstringLength))
            {
                //Ignore very short substrings for long source strings
                if (6*_substringLength < _sourceLength)
                {
                    ++_substringLength;
                    continue;
                }
                
                var _pos = 1 + __maxSubstringLength - _substringLength;
                repeat(_sourceLength + _substringLength - 1)
                {
                    _funcPush(string_copy(_string, _pos, _substringLength), _sourceString);
                    ++_pos;
                }
                
                ++_substringLength;
            }
            
            ++_i;
        }
    }
    
    static SetString = function(_inString)
    {
        if (_inString != __string)
        {
            __Clear();
            __string = _inString;
            
            var _ngramDict = __ngramDict;
            
            var _resultDict  = {};
            var _resultArray = __resultArray;
            
            if (variable_struct_exists(__exactDict, __string))
            {
                var _result = {
                    word: __string,
                    strength: infinity,
                };
                
                array_push(_resultArray, _result);
                _resultDict[$ __string] = _result;
            }
            
            var _sourceString = __string;
            var _sourceLength = string_length(_sourceString);
            
            var _string = _sourceString;
            repeat(__maxSubstringLength-1)
            {
                _string = " " + _string + " ";
            }
            
            var _substringLength = 1;
            repeat(min(_sourceLength, __maxSubstringLength))
            {
                var _pos = 1 + __maxSubstringLength - _substringLength;
                repeat(_sourceLength + _substringLength - 1)
                {
                    var _substring = string_copy(_string, _pos, _substringLength);
                    
                    var _ngramArray = _ngramDict[$ _substring];
                    if (is_array(_ngramArray))
                    {
                        var _j = 0;
                        repeat(array_length(_ngramArray))
                        {
                            var _foundString = _ngramArray[_j];
                            
                            var _result = _resultDict[$ _foundString];
                            if (_result == undefined)
                            {
                                _result = {
                                    word: _foundString,
                                    strength: 1,
                                };
                                
                                _resultDict[$ _foundString] = _result;
                                array_push(_resultArray, _result);
                            }
                            else
                            {
                                ++_result.strength;
                            }
                            
                            ++_j;
                        }
                    }
                    
                    ++_pos;
                }
                
                ++_substringLength;
            }
            
            array_sort(_resultArray, function(_a, _b)
            {
                return sign(_b.strength - _a.strength);
            });
            
            __wordArrayDirty = true;
        }
    }
    
    static GetString = function()
    {
        return __string;
    }
    
    static SetMaxResults = function(_value)
    {
        if (_value != __maxResults)
        {
            __Clear();
            __maxResults = _value;
        }
    }
    
    static GetMaxResults = function()
    {
        return __maxResults;
    }
    
    static GetResultArray = function()
    {
        return __resultArray;
    }
    
    static GetWordArray = function()
    {
        if (__wordArrayDirty)
        {
            array_resize(__wordArray, 0);
            
            var _i = 0;
            repeat(min(array_length(__resultArray), __maxResults))
            {
                array_push(__wordArray, __resultArray[_i].word);
                ++_i;
            }
        }
        
        return __wordArray;
    }
}