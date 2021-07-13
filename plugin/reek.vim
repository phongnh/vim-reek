" reek.vim - Code smell detector for Ruby in Vim
" Author: Rainer Borene <https://github.com/rainerborene>
" Version: 1.0

if exists('g:loaded_reek')
  finish
endif
let g:loaded_reek = 1

if !exists('g:reek_always_show')
  let g:reek_always_show = 1
endif

if !exists('g:reek_debug')
  let g:reek_debug = 0
endif

if !exists('g:reek_on_loading')
  let g:reek_on_loading = 1
endif

if !exists('g:reek_cmd')
    let g:reek_cmd = 'reek'
endif

if !exists('g:reek_opts')
    let g:reek_opts = ''
endif

if exists('*trim')
  function! s:Trim(str) abort
    return trim(a:str)
  endfunction
else
  function! s:Trim(str) abort
    return substitute(a:str, '^\s*\(.\{-}\)\s*$', '\1', '')
  endfunction
endif

function! s:BuildReekCommand() abort
  let l:cmd = filter(map([g:reek_cmd, g:reek_opts], 's:Trim(v:val)'), 'strlen(v:val)')
  return join(l:cmd, ' ')
endfunction

function! s:Reek() abort
  if exists('g:reek_line_limit') && line('$') > g:reek_line_limit
    return
  endif

  let l:reek_cmd = s:BuildReekCommand()
  let l:cmd = l:reek_cmd . ' ' . expand("%:p")
  let s:quickfix_title = s:Trim(l:reek_cmd . ' ' . expand("%:p:."))

  let metrics = system(l:cmd)
  let loclist = []

  if g:reek_debug
    echom metrics
  endif

  for line in split(metrics, '\n')
    let err = matchlist(line, '\v\s*\[(.*)\]:(.*)')
    if strlen(get(err, 2)) > 1
      for lnum in split(err[1], ', ')
        call add(loclist, { 'bufnr': bufnr('%'), 'lnum': lnum, 'text': err[2] })
      endfor
    end
  endfor

  call setloclist(0, loclist)
  return len(loclist) > 0
endfunction

" Function to run reek and display location list
function s:RunReek() abort
  if s:Reek()
    exec has("gui_running") ? "redraw!" : "redraw"
    lopen
    let w:quickfix_title = s:quickfix_title
  else
    lclose
    echom 'Reek: Passed. Hooray!'
  endif
endfunction

" Only set up automatic call if we request reek_on_loading
if g:reek_on_loading
  " Function to run reek on loading
  function! s:ReekOnLoading() abort
    if s:Reek()
      exec has("gui_running") ? "redraw!" : "redraw"
      if g:reek_always_show
        ll
      endif
    else
      lclose
    endif
  endfunction

  augroup reek_plugin
    autocmd!
    autocmd BufReadPost,BufWritePost,FileReadPost,FileWritePost *.rb call s:ReekOnLoading()
  augroup END
endif

command! RunReek call s:RunReek()
