command -bang -count=1 QNext call <sid>nav(1, expand('<bang>'), expand('<count>'), v:null)
command -bang -count=1 QPrev call <sid>nav(-1, expand('<bang>'), expand('<count>'), v:null)
command -bang -count=1 QFNext call <sid>nav(1, expand('<bang>'), expand('<count>'), 'c')
command -bang -count=1 QFPrev call <sid>nav(-1, expand('<bang>'), expand('<count>'), 'c')
command -bang -count=1 LLNext call <sid>nav(1, expand('<bang>'), expand('<count>'), 'l')
command -bang -count=1 LLPrev call <sid>nav(-1, expand('<bang>'), expand('<count>'), 'l')
command -bang QFOpen call luaeval("require'qf_helper'.open('c', {enter = _A == ''})", expand('<bang>'))
command -bang LLOpen call luaeval("require'qf_helper'.open('l', {enter = _A == ''})", expand('<bang>'))
command -bang QFToggle call luaeval("require'qf_helper'.toggle('c', {enter = _A == ''})", expand('<bang>'))
command -bang LLToggle call luaeval("require'qf_helper'.toggle('l', {enter = _A == ''})", expand('<bang>'))

function! s:nav(dir, bang, count, qftype) abort
  let l:opts = {
        \ 'bang': a:bang,
        \ 'qftype': a:qftype,
        \}
  call luaeval("require'qf_helper'.navigate(_A[1], _A[2])", [a:dir*a:count, l:opts])
endfunction
