" Allows for the use of multiple dictionaries as if one big dictionary.
"
" All the API optionally take the key of the exact sub-dictionary or will iterate over them all. The call to put() is the only exception and requires an
" explicit sub-dictionary. (And, obviously, get_dictionary() as that returns a sub-dictionary.)

function! MultiDictionary#New()
  return { 'data': {},
        \ 'put': function( "MultiDictionary#Put" ),
        \ 'remove': function( "MultiDictionary#Remove" ),
        \ 'get': function( "MultiDictionary#Get" ),
        \ 'keys': function( "MultiDictionary#Keys" ),
        \ 'values': function( "MultiDictionary#Values" ),
        \ 'has_key': function( "MultiDictionary#HasKey" ),
        \ 'has_dictionary': function( "MultiDictionary#HasDictionary" ),
        \ 'get_dictionary': function( "MultiDictionary#GetDictionary" ) }
endfunction


" Regular methods
function! MultiDictionary#Remove( key, ... ) dict
  let dictionaryName = exists( "a:1" ) ? a:1 : ''

  if ( dictionaryName == '' )
    for dictionaryName in keys( self.data )
      if ( has_key( self.data[ dictionaryName ], a:key ) )
        return remove( self.data[ dictionaryName ], a:key )
      endif
    endfor

    throw "No key matching " . a:key . " found."
  endif

  return remove( self.data[ dictionaryName ], a:key )
endfunction

function! MultiDictionary#Keys( ... ) dict
  let dictionaryName = exists( "a:1" ) ? a:1 : ''

  if ( dictionaryName == '' )
    let result = []

    for dictionaryName in keys( self.data )
      call extend( result, keys( self.data[ dictionaryName ] ) )
    endfor

    return result
  endif

  return keys( self.data[ dictionaryName ] )
endfunction

function! MultiDictionary#Values( ... ) dict
  let dictionaryName = exists( "a:1" ) ? a:1 : ''

  if ( dictionaryName == '' )
    let result = []

    for dictionaryName in keys( self.data )
      call extend( result, values( self.data[ dictionaryName ] ) )
    endfor

    return result
  endif

  return values( self.data[ dictionaryName ] )
endfunction

function! MultiDictionary#HasKey( key, ... ) dict
  let dictionaryName = exists( "a:1" ) ? a:1 : ''

  if ( dictionaryName == '' )
    for dictionaryName in keys( self.data )
      if ( has_key( self.data[ dictionaryName ], a:key ) )
        return 1
      endif
    endfor

    return 0
  endif

  return has_key( self.data[ dictionaryName ], a:key )
endfunction

function! MultiDictionary#GetDictionary( dictionaryName, ... ) dict
  let createIfNecessary = exists( "a:1" ) ? a:1 : 0

  if ( !has_key( self.data, a:dictionaryName ) )
    if ( createIfNecessary )
      let self.data[ a:dictionaryName ] = {}
    else
      throw "No dictionary matching key " . a:dictionaryName . " found."
    endif
  endif

  return self.data[ a:dictionaryName ]
endfunction

function! MultiDictionary#HasDictionary( dictionaryName ) dict
  return has_key( self.data, a:dictionaryName )
endfunction

function! MultiDictionary#Put( dictionaryName, key, value ) dict
  let dictionary          = self.get_dictionary( a:dictionaryName, 1 )
  let dictionary[ a:key ] = a:value
endfunction

function! MultiDictionary#Get( key, ... ) dict
  let dictionaryName = exists( "a:1" ) ? a:1 : ''

  if ( dictionaryName == '' )
    for dictionaryName in keys( self.data )
      let dictionary = self.data[ dictionaryName ]

      if ( has_key( dictionary, a:key ) )
        return dictionary[ a:key ]
      endif
    endfor

    throw "No key matching " . a:key . " found."
  else
    let dictionary = self.data[ dictionaryName ]

    return dictionary[ a:key ]
  endif
endfunction
