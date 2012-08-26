" Works like a list that is a set (only contains unique entries).

function! Set#Add( item ) dict
  if ( index( self.data, a:item ) < 0 )
    let self.data += [ a:item ]

    return 1
  endif

  return 0
endfunction

" The first parameter dictates whether the sort is in-place (it isn't, by default) and actually modifies the data. The second parameter is the comparator to
" pass to the internal sort().
function! Set#Sort( ... ) dict
  let inPlace    = exists( "a:1" ) && a:1 == 1
  let comparator = exists( "a:2" ) ? a:2 : ''

  let data = inPlace ? self.data : copy( self.data )

  if ( comparator != '' )
    return sort( data, comparator )
  endif

  return sort( data )
endfunction

" Takes a list of values and adds them to the set.
function! Set#AddAll( list ) dict
  for item in a:list
    call self.add( item )
  endfor
endfunction

" Useful if "data" is manipulated directly as it might contain duplicates after.
function! Set#Optimize() dict
  let oldData   = self.data
  let self.data = []

  call self.addAll( oldData )
endfunction

function! Set#NewSet()
  return { 'data' : [],
        \ 'add' : function( "Set#Add" ),
        \ 'sortedData' : function( "Set#Sort" ),
        \ 'addAll' : function( "Set#AddAll" ),
        \ 'optimize': function( 'Set#Optimize' ) }
endfunction
