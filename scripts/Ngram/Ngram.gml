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

function Ngram(_caseSensitive=true, _nGramMin=1, _nGramMax=infinity) constructor
{
    // Changed to gram min/max for better control commonly elastic searching will always ignore the first letter, or sometimes the second letter, this add basically no additional cpu overhead. -@Tinkerer_Red (2023/11/20 YYYY/MM/DD)
		__nGramMin = max(1, _nGramMin);
		__nGramMax = max(__nGramMin, _nGramMax);
		
		// Optional Case sensativity. -@Tinkerer_Red (2023/11/20 YYYY/MM/DD)
		__caseSensitive = _caseSensitive;
		
    __exactDict = {};
    __ngramDict = {};
    
    __string     = "";
    __maxResults = 10;
    
    __wordArray = [];
    __strengthArray = [];
    
    __Clear();
    
    static __Clear = function()
    {
        __wordArrayDirty = true;
        __strengthArrayDirty = true;
        array_resize(__wordArray, 0);
        array_resize(__strengthArray, 0);
        __resultArray = [];
    }
    
    static SetLexiconArray = function(_array, _stringWidthBuffer=4)
    {
        __Clear();
        
        __exactDict = {};
        __ngramDict = {};
        
        static __funcPush = function(_substring, _string)
        {
            var _array = __ngramDict[$ _substring];
            if (not is_array(_array))
            {
								// Left for debugging. -@Tinkerer_Red (2023/11/20 YYYY/MM/DD)
								//show_debug_message(["_substring", _substring])
                _array = [_string];
                __ngramDict[$ _substring] = _array;
            }
            else
            {
                if (!array_contains(_array, _string)) {
									array_push(_array, _string);
								}
            }
        }
        
				var _CompletedGrams = [];
				
        var _i = 0;
        repeat(array_length(_array))
        {
            var _sourceString = (__caseSensitive) ? _array[_i] : string_lower(_array[_i]);
            
            __exactDict[$ _sourceString] = true;
            
						// Left for debugging. -@Tinkerer_Red (2023/11/20 YYYY/MM/DD)
						//show_debug_message(["_sourceString", _sourceString])
						
            var _string = _sourceString;
						var _sourceLength = string_length(_sourceString);
						
						var _nGramMin = __nGramMin;
						var _nGramMax = min(__nGramMax, _sourceLength);
						var _nGramLength = _nGramMax - _nGramMin;
						
						// For optimization sake you can resize the array to 0 then to the factorial of _sourceLength, but did not do this for readability sake. -@Tinkerer_Red (2023/11/20 YYYY/MM/DD)
						array_resize(_CompletedGrams, 0); //reuse the same array
						
						var _nGramSize = _nGramMin;
						repeat(_nGramLength + 1)
						{
							
							var _pos = 1;
							repeat(_sourceLength - _nGramSize + 1)
							{
								
								var _gramSubString = string_copy(_string, _pos, _nGramSize);
								if (!array_contains(_CompletedGrams, _gramSubString))
								{
									
									// Left for debugging. -@Tinkerer_Red (2023/11/20 YYYY/MM/DD)
									//show_debug_message([ $"string_copy({_string}, {_pos}, {_nGramSize})", _gramSubString])
									__funcPush(_gramSubString, _sourceString);
									
									// If using the factorial resize mentioned above change this to an index assignment. -@Tinkerer_Red (2023/11/20 YYYY/MM/DD)
									array_push(_CompletedGrams, _gramSubString);
									
								}
								
								++_pos;
							}
							
							++_nGramSize;
						}//end repeat loop
						
            ++_i;
        }
    }
    
    static SetString = function(_inString, _caseSensitive=__caseSensitive, _nGramMin=__nGramMin, _nGramMax=__nGramMax)
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
            
            var _sourceString = (_caseSensitive) ? __string : string_lower(__string);
            var _sourceLength = string_length(_sourceString);
            
            var _string = _sourceString;
            
						
						//var _nGramMin = __nGramMin;
						_nGramMax = min(_nGramMax, _sourceLength);
						var _nGramLength = _nGramMax - _nGramMin;
						
						var _nGramSize = _nGramMin;
						repeat(_nGramLength + 1)
						{
							
							var _pos = 1;
							repeat(_sourceLength - _nGramSize + 1)
							{
								
								var _gramSubString = string_copy(_string, _pos, _nGramSize);
								
								var _nGramReturnArray = _ngramDict[$ _gramSubString];
								
								// Left for debugging. -@Tinkerer_Red (2023/11/20 YYYY/MM/DD)
								//show_debug_message(string_join("\n", $"_substring {_gramSubString}", $"_ngramArray {_nGramReturnArray}" ))
								
								if (is_array(_nGramReturnArray))
                    {
                        var _j = 0;
                        repeat(array_length(_nGramReturnArray))
                        {
                            var _foundString = _nGramReturnArray[_j];
                            
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
																// Optional Alternitive and really dependant on your use case, personally i prefer the method used above. -@Tinkerer_Red (2023/11/20 YYYY/MM/DD)
																// _result.strength += _nGramSize;
                            }
                            
                            ++_j;
                        }
                    }
								
								++_pos;
							}
							
							++_nGramSize;
						}//end repeat loop
						
            
            array_sort(_resultArray, function(_a, _b)
            {
                return sign(_b.strength - _a.strength);
            });
            
            __wordArrayDirty = true;
            __strengthArrayDirty = true;
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
		
		static GetStrengthArray = function()
    {
        if (__strengthArrayDirty)
        {
            array_resize(__strengthArray, 0);
            
            var _i = 0;
            repeat(min(array_length(__resultArray), __maxResults))
            {
                array_push(__strengthArray, __resultArray[_i].strength);
                ++_i;
            }
        }
        
        return __strengthArray;
    }
}