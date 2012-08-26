" " Template replacement
" let g:testString = 'public void < T > testFunction ( Map< String, < ? extends Map< T > > > testMap )'
" let var1       = functions#RecursiveReplace( g:testString, '\%(<\s*\([^<>]\{-}\)\s*>\)', '<\2>', '_test', '_' )
" let myList     = []
"
" for expression in var1[ 1 ]
"   let myList += [ '<' . expression . '>' ]
" endfor
"
" let g:testString = functions#RecursiveRestore( var1[ 0 ], myList, '_test', '_' )
"
" " String quote replacement
" let var2 = functions#RecursiveReplace( str, '\(\([''"]\).\{-}[^\\]\2\)', '\1', '_test', '_' )
function! functions#RecursiveReplace( str, regexp, saveString, prefix, suffix )
  let newString = a:str
  let oldString = ''
  let counter   = 0
  let savedMap  = []

  while ( newString != oldString )
    let oldString = newString

    let matchedList = matchlist( oldString, a:regexp )

    if ( len( matchedList ) > 0 )
      let [ original, type; remainder ] = matchedList
      let replacement = a:prefix . counter . a:suffix
      let savedMap   += [ type ]

      " let savedString = substitute( oldString, '.\{-}' . a:regexp . '.\{-}', a:saveString, '' )
      " let savedString = substitute( oldString, '.*' . a:regexp . '.*', a:saveString, '' )
      " let savedString = substitute( oldString, a:regexp, a:saveString, '' )

      let newString   = substitute( oldString, a:regexp, replacement, '' )

      " call EchoLater#EchoToVariable( "savedString: ", string( savedString ), '', 1 )
      " echo savedString

      let counter += 1
    endif
  endwhile

  return [ newString, savedMap ]
endfunction

function! functions#RecursiveRestore( str, replacements, prefix, suffix )
  let result = a:str

  let counter = len( a:replacements ) - 1

  while ( counter >= 0 )
    let replacement = a:prefix . counter . a:suffix
    let result      = substitute( result, replacement, a:replacements[ counter ], '' )

    let counter -= 1
  endwhile

  return result
endfunction

function! functions#EchoHlParse( sameLine, args )
  let [ original, highlight, message; remainder ] = matchlist( a:args, '^\(\S\+\)\s\+\(.*\)$' )

  call functions#EchoHl( a:sameLine, highlight, eval( message ) )
endfunction

function! functions#EchoHl( sameLine, highlight, message )
  let command     = a:sameLine ? 'echon' : 'echo'
  let messageType = type( a:message )

  execute 'echohl ' . a:highlight

  if ( messageType == type( 0 ) || messageType == type( "" ) )
    execute command . ' "' . escape( a:message, '"' ) . '"'
  else
    execute command . ' ' . string( a:message )
  endif

  echohl None
endfunction

function! functions#HgStatus()
  let root  = expand( "%:p" )
  let lines = split( system( "hg status" ), "\<nl>" )

  if ( len( lines ) == 1 && lines[ 0 ] =~ '^abort' )
    echohl ErrorMsg
    echo lines[ 0 ]
    echohl None

    return
  endif

  let newLines = []

  for line in lines
    let [ original, flags, rootPath, restOfPath; remainder ] = matchlist( line, '^\(\S\+\s\+\)\([^\\/]*\)\(.*\)$' )
    let base                                                 = substitute( root, '^\(.\{-}\)' . rootPath . '.*', '\1', '' )

    call add( newLines, flags . base . rootPath . restOfPath )
  endfor

  let old_efm = &errorformat
  set errorformat=%m\ %f
  cexpr newLines
  let &errorformat = old_efm

  botright copen
endfunction

function! functions#FollowLinks( type, command )
  redir => temp
  execute 'silent! ' . a:type . ' ' . a:command
  redir END

  let lines = split( temp, "\<nl>" )

  if ( len( lines ) < 2 )
    call functions#EchoHl( 0, "Error", "No " . a:type . " starting with '" . a:command . "' found." )

    return
  endif

  if ( len( lines ) > 2 )
    call functions#EchoHl( 0, "WarningMsg", "Multiple " . a:type . "s (" . ( len( lines ) - 1 ) . ") starting with '" . a:command . "' found. Showing the first one." )
  endif

  let offset      = stridx( lines[ 0 ], 'Definition' )
  let commandCall = lines[ 1 ][ offset : ]

  echo "The " . a:type . " " . a:command . " executes " . commandCall . "."

  if ( commandCall =~ '\C\<call\>' )
    let functionName = substitute( commandCall, '^.*\<call \([^( \t]*\)(.*', '\1', '' )

    execute 'verb function ' . functionName
  endif
endfunction

function! functions#ShowCommandFunction( command )
  call functions#FollowLinks( 'command', a:command )
endfunction

" Tuesday, May 29, 2012:
" Too hard; avoiding it for now.
" function! functions#ShowMap( mapLhs )
"   call functions#FollowLinks( 'map', a:mapLhs )
" endfunction

" Given three pieces of text, a full text width and the character to use, creates three sections of text, one left-aligned, one centered and one right-aligned.
" Any of the three text pieces may be empty.
"
" If the size is 0, the current &textwidth is used.
"
" If the padChar is empty, spaces are used.
function! functions#LeftCenterRight( leftText, centerText, rightText, size, padChar )
  let size    = a:size > 0 ? a:size : &textwidth
  let padChar = a:padChar != '' ? a:padChar[ 0 ] : ' '

  let gapAroundCenter = size - strlen( a:centerText )
  let leftGap         = gapAroundCenter / 2
  let rightGap        = leftGap * 2 == gapAroundCenter ? leftGap : leftGap + 1

  let result = functions#LeftJustify( a:leftText, leftGap, padChar )
  let result .= a:centerText
  let result .= functions#RightJustify( a:rightText, rightGap, padChar )

  return result
endfunction

" Prepends enough copies of padChar to make text size characters in length
"
" Replaces the old LPad
function! functions#RightJustify( text, size, padding )
  let result = repeat( a:padding, a:size - strlen( a:text ) ) . a:text

  return RTruncate( result, a:size )
endfunction

" Appends enough copies of padChar to make text size characters in length
"
" Replaces the old RPad
function! functions#LeftJustify( text, size, padding )
  let result = a:text . repeat( a:padding, a:size - strlen( a:text ) )

  return Truncate( result, a:size )
endfunction

" Runs 2html.vim on all open buffers
function! functions#Alltohtml()
  bufdo set et lz|%retab!|so $VIMRUNTIME/syntax/2html.vim|w|bd|undo
endfunction

" From John Beckett: johnb.beckett@gmail.com
" (Modified to work off multiple lines and accept spaces between numbers by Salman Halim on Friday, July 06, 2012.)
" Write a binary file (no newline at end) of characters translated from pairs of hex ASCII characters on selected lines (defaults to current line).
" 41          61
" 2C2E
" 2D
function! functions#WriteChars( outfile, lines )
  let chars = ''

  for line in a:lines
    let i = 0

    while ( i <= len( line ) - 1 )
      if ( line[ i ] !~ '\s' )
        let chars .= nr2char( '0x' . line[ i : i + 1 ] )

        let i += 1
      endif

      let i += 1
    endwhile
  endfor

  call writefile( [ chars ], a:outfile, 'b' )
endfunction

function! functions#SingularOrPlural( number, singular, plural )
  return a:number == 1 ? a:singular : a:plural
endfunction

" Returns a dictionary that can be passed to functions#RestoreMarks to restore the specified marks. For example, calling with "<>" can be used to save and
" restore the visual mode marks.
function! functions#SaveMarks( marks )
  let marks = substitute( a:marks, '\s\+', '', 'g' )

  let result = {}
  let i      = 0

  while ( i < len( marks ) )
    let mark           = marks[ i ]
    let result[ mark ] = getpos( "'" . mark )

    let i += 1
  endwhile

  return result
endfunction

function! functions#RestoreMarks( markDictionary )
  for mark in keys( a:markDictionary )
    let coordinates = a:markDictionary[ mark ]

    call setpos( "'" . mark, coordinates )
  endfor
endfunction

" Sometimes getchar() can return a number; this variation always returns a character.
function! functions#GetCharacter()
  let char = getchar()

  return type( char ) == type( 0 ) ? nr2char( char ) : char
endfunction

" Given a list of strings, returns the length of the longest item.
function! functions#GetMaxLen( list )
"   let result = 0
"
"   for item in a:list
"     let result = result < len( item ) ? len( item ) : result
"   endfor
"
"   return result
  return max( map( copy( a:list ), "len( v:val )" ) )
endfunction

" Concatenates two strings, placing a space between them if neither is
" empty; if either is empty, the result is simply the non-empty one; if
" both are empty, returns the empty string.
function! functions#AddWithSpace( original, addition, ... )
  let result        = ""
  let originalEmpty = a:original == ''
  let additionEmpty = a:addition == ''
  let separator     = exists( "a:1" ) ? a:1 : " "

  if ( originalEmpty && additionEmpty )
    let result = ""
  elseif ( originalEmpty )
    let result = a:addition
  elseif ( additionEmpty )
    let result = a:original
  else
    let result = a:original . separator . a:addition
  endif

  return result
endfunction

" Converts 'anInterestingPhrase' or 'AN_INTERESTING_PHRASE' to 'an intersting phrase'.
function! functions#MakeWords( text )
  return tolower( substitute( substitute( a:text, '\C\([^A-Z]\)\([A-Z]\)', '\1 \2', 'g' ), '_', '', 'g' ) )
endfunction

" Works just like the Vim 7 sort(), optionally taking in a comparator (just like the original), except that duplicate entries will be removed.
function! functions#SortUnique( list, ... )
  let uniqueList = Set#NewSet()

  for i in a:list
    call uniqueList.add( i )
  endfor

  return uniqueList.sortedData()

"   let dictionary = {}
"
"   for i in a:list
"     let dictionary[ string( i ) ] = i
"   endfor
"
"   let result = []
"
"   if ( exists( 'a:1' ) )
"     let result = sort( keys( dictionary ), a:1 )
"   else
"     let result = sort( keys( dictionary ) )
"   endif
"
"   return result
endfunction

" Lists the contents of the list and lets the user enter a number corresponding to the index chosen. Returns -1 if nothing is selected.
"
" The input values presented to the user are 1-based but the return is 0-based.
function! functions#InputFromList( list, ... )
  let prompt       = exists( "a:1" ) && a:1 != '' ? a:1 : 'Enter the number next to your choice: '
  let defaultValue = exists( "a:2" ) && a:2 != '' ? a:2 : ''

  let numberLength = strlen( len( a:list ) )

  let i = 0

  while ( i < len( a:list ) )
    echohl LineNr
    echo functions#RightJustify( i + 1, numberLength, ' ' ). ':'
    echohl None

    echon ' ' . a:list[ i ]

    let i += 1
  endwhile

  echon "\n"

  return str2nr( input( prompt, defaultValue ) ) - 1
endfunction
