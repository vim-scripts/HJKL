" Maximize window before starting new game to get better view.
" type :HJKL to start new game
"
let s:w=localtime()
let s:z=s:w*22695477
"maze represented in two-dim array of char
let s:maze=[]
"size of maze
let s:R=15
let s:C=15

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

"return random double in [0,1)
function! s:RandDouble()
	let magic=89513
	return s:Rand()%magic*1.0/magic
endfunction

function! s:Build2DArray(n,m,v)
	let res=[]
	for i in range(a:n)
		let row=[]
		for j in range(a:m)
			call add(row,a:v)
		endfor
		call add(res,row)
	endfor
	return res
endfunction

function! s:RemoveWallWithProbability(i,j,p)
	if s:RandDouble() < a:p
		let s:maze[a:i][a:j]=' '
		return 1
	endif
	return 0
endfunction

function! s:BuildFullGrid()
	let R=s:R
	let C=s:C
	let s:maze=s:Build2DArray(2*R+1,2*C+1,' ')
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
	let s:maze[s:target[0]][s:target[1]]='X'
	let s:maze[s:you[0]][s:you[1]]='@'
	for i in range(len(s:maze))
		"line index starts from 1
		let line=join(s:maze[i],'')
		let line=substitute(line,' ','`','g')	"for highlight matching. ' ' appears in normal text too often
		call setline(i+1,line)
	endfor
	let s:maze[s:you[0]][s:you[1]]=' '
	let s:maze[s:target[0]][s:target[1]]=' '
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

function! s:Valid(i,j)
	return a:i>=0 && a:i<=2*s:R && a:j>=0 && a:j<=2*s:C
endfunction

function! s:GetProbability(i,j)
	let i=a:i
	let j=a:j
	let d=[[0,-2],[-1,-1],[1,-1],[0,2],[-1,1],[1,1]]
	let ct=0
	let filled=0
	for p in d
		let ti=i+p[i%2]
		let tj=j+p[j%2]
		if s:Valid(ti,tj)
			let ct+=1
			if s:maze[ti][tj]!=' '
				let filled+=1
			endif
		endif
	endfor
	let r=1.0*filled/ct
	return pow(r,2)
endfunction

function! s:RandomlyRemoveWalls()
	let s:p=[]
	let R=s:R
	let C=s:C
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
		let p=s:GetProbability(i,j)
		if s:RemoveWallWithProbability(i,j,p)
			if idx==0
				call s:Merge(x*C+y,(x-1)*C+y)
			elseif idx==1
				call s:Merge(x*C+y,(x+1)*C+y)
			elseif idx==2
				call s:Merge(x*C+y,x*C+y-1)
			else
				call s:Merge(x*C+y,x*C+y+1)
			endif
		endif
	endwhile
endfunction


function! s:FindFarthestPoint()
	"starting point is s:you's logical coordinate
	let si=s:you[0]/2
	let sj=s:you[1]/2
	let Q=[[si,sj]]
	let dis=s:Build2DArray(s:R,s:C,-1)
	let dis[si][sj]=0
	let maxDis=0
	let d=[[-1,0],[1,0],[0,-1],[0,1]]
	while len(Q)!=0
		let p=get(Q,0)
		call remove(Q,0)
		let i=p[0]
		let j=p[1]
		for idx in range(4)
			let ti=i+d[idx][0]
			let tj=j+d[idx][1]
			if s:maze[i+1+ti][j+1+tj]==' ' && dis[ti][tj]==-1
				call add(Q,[ti,tj])
				let dis[ti][tj]=dis[i][j]+1
				let maxDis=max([maxDis,dis[ti][tj]])
			endif
		endfor
	endwhile
	for i in range(s:R)
		for j in range(s:C)
			if dis[i][j]==maxDis
				return [i*2+1,j*2+1]
			endif
		endfor
	endfor
endfunction

function! s:BuildMaze()
	let R=s:R
	let C=s:C
	call s:BuildFullGrid()
	call s:RandomlyRemoveWalls()
	let s:you=[1,1]
	let s:target=s:FindFarthestPoint()
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
	if s:maze[i][j]==' '
		let s:you[0]=i
		let s:you[1]=j
	endif
	return 0
endfunction


function! s:CheckWin()
	return s:you[0]==s:target[0] && s:you[1]==s:target[1]
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
			echo "type any key to continue"
			break
		endif
		let c=getchar()
		if s:HandleKeyInput(c)==1
			break
		endif
	endwhile
endfunction

function! s:HJKL(...)

	if a:0==2
		if a:1 >= 5 && a:1 <= 30
			let s:R=a:1
		endif
		if a:2 >= 5 && a:2<= 40
			let s:C=a:2
		endif
	endif
	"build random maze
	call s:BuildMaze()
	"create new window
	
	"create new window for game
	new
	"setup syntax highlight
	syntax match Wall "+"
	syntax match Wall "-"
	syntax match Wall "|"
	syntax match Empty "`"
	syntax match Obj "@"
	syntax match Obj "X"

	hi Wall ctermfg=Black ctermbg=Black guibg=Black guifg=Black
	hi Empty ctermfg=White ctermbg=White guibg=White guifg=White
	hi Obj ctermfg=Black ctermbg=White guibg=White guifg=Black
	"main loop
	call s:MainLoop()

endfunction

command! -nargs=* HJKL call s:HJKL(<f-args>)
