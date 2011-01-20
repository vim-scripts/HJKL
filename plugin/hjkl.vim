" Maximize window before starting new game to get better view.
" type :HJKL to start new game
"
let s:w=localtime()
let s:z=s:w*22695477
let s:maze=[]

function! s:Rand()
	let s:z=36969 * (s:z % 65536) + s:z / 65536
	let s:w=18000 * (s:w % 65536) + s:w / 65536
	let res=s:z/65536 + s:w
	return res<0 ? -res : res
endfunction

"return integer within [a,b)
function! s:RandInt(a,b)
	return s:Rand()%(a:b-a:a)+a:a
endfunction

function! s:BuildFullGrid(R,C)
	let s:maze=[]
	let R=a:R
	let C=a:C
	for i in range(0,2*R)
		let row=[]
		for j in range(0,2*C)
			call add(row,' ')
		endfor
		call add(s:maze,row)
	endfor
	for i in range(0,R)
		for j in range(0,C)
			let s:maze[2*i][2*j]='+'
		endfor
	endfor
	for j in range(0,C)
		for i in range(0,R-1)
			let s:maze[2*i+1][j*2]='|'
		endfor
	endfor
	for i in range(0,R)
		for j in range(0,C-1)
			let s:maze[2*i][j*2+1]='-'
		endfor
	endfor
endfunction

function! s:PrintMaze()
	let s:maze[s:you[0]][s:you[1]]='@'
	for i in range(len(s:maze))
		"line index starts from 1
		let line=join(s:maze[i],'')
		call setline(i+1,line)
	endfor
	let s:maze[s:you[0]][s:you[1]]=' '
	call setline(len(s:maze)+1,"")
	call setline(len(s:maze)+2,"Use h,j,k,l to bring you('@') to the target('X')")
	call setline(len(s:maze)+3,"type q to quit the game")
endfunction

let s:p=[]    "parent array for disjoint set
function! s:Root(i)
	let i=a:i
	if s:p[i] == i
		return i
	else
		let s:p[i]=s:Root(s:p[i])
		return s:p[i]
	endif
endfunction

function! s:Merge(a,b)
	let a=a:a
	let b=a:b
	let s:p[s:Root(a)]=s:Root(b)
endfunction

function! s:RandomlyRemoveWalls(R,C)
	let s:p=[]
	let R=a:R
	let C=a:C
	let d=[[-1,0],[1,0],[0,-1],[0,1]]
	for i in range(R*C)
		call add(s:p,i)
	endfor
	while s:Root(0)!=s:Root(R*C-1)
		let x=s:RandInt(0,R)
		let y=s:RandInt(0,C)
		let i=1+2*x
		let j=1+2*y
		let idx=s:RandInt(0,4)
		let i+=d[idx][0]
		let j+=d[idx][1]
		if i==0 || i==2*R || j==0 || j==2*C || s:maze[i][j]==' '
			continue
		endif
		let s:maze[i][j]=' '
		if idx==0
			call s:Merge(x*C+y,(x-1)*C+y)
		elseif idx==1
			call s:Merge(x*C+y,(x+1)*C+y)
		elseif idx==2
			call s:Merge(x*C+y,x*C+y-1)
		else
			call s:Merge(x*C+y,x*C+y+1)
		endif
	endwhile
endfunction

function! s:BuildMaze(R,C)
	let R=a:R
	let C=a:C
	call s:BuildFullGrid(R,C)
	call s:RandomlyRemoveWalls(R,C)
	let s:maze[2*R-1][2*C-1]='X'
endfunction

function! s:HandleKeyInput(c)
	let c=nr2char(a:c)
	if c=='q'
		q!
		return 1
	endif
	let i=s:you[0]
	let j=s:you[1]
	if c=='h'
		let j-=1
	elseif c=='j'
		let i+=1
	elseif c=='k'
		let i-=1
	elseif c=='l'
		let j+=1
	endif
	if s:maze[i][j]==' ' || s:maze[i][j]=='X'
		let s:you[0]=i
		let s:you[1]=j
	endif
	return 0
endfunction




function! s:CheckWin()
	return s:you[0]==2*s:R-1 && s:you[1]==2*s:C-1
endfunction

function! s:MainLoop()
	while 1
		"ensure enough size. Resize each iteration because user may
		"resize the window
		resize 100
		"print maze in new window
		call s:PrintMaze()
		redraw
		if s:CheckWin()
			echo "Congratulations!"
			echo "You Win!"
			break
		endif
		let c=getchar()
		if s:HandleKeyInput(c)==1
			break
		endif
	endwhile
endfunction

function! s:HJKL(...)
	" 
	"determin size of maze
	"
	let s:R=15
	let s:C=20
	if a:0==2
		if a:1 >= 5 && a:1 <= 20
			let s:R=a:1
		endif
		if a:2 >= 5 && a:2<= 20
			let s:C=a:2
		endif
	endif

	"build random maze
	call s:BuildMaze(s:R,s:C)
	"create new window
	let s:you=[1,1]

	"create new window for game
	new

	"main loop
	call s:MainLoop()

endfunction

command! -nargs=* HJKL call s:HJKL(<f-args>)
