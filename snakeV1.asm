;*******************************************************************************************************;
;		     Instituto Tecnológico de Costa Rica	         											;
;		Área Académica de Ingeniería en Computadores         											;
;            Principios de Sistemas Operativos               											;
;                        Tarea 2                            											;
;                                                            											;
; Prof. Jason Leitón Jiménez								 											;
; Integrantes:              								 											;
;   - Bryan Alexander Masis Mora	    					 											;
;   - Cristofer Alberto Fernández Fernández				  	 											;
;   - María Alejandra Castrillo Muñoz    					 											;
;Basado en el codigo encontrado en https://gitlab.com/pmikkelsen/asm_snake/blob/master/snake.asm#L126	;                                                            ;
;*******************************************************************************************************;
 
    bits 16								;16 bits mode
    org 0x0000
    mov 	ax, cs
    mov 	ds, ax 							; set DS to the point where code is loaded
	mov		ah, 0x01
	mov		cx, 0x2000
	int 	0x10							
	mov		ax, 0x0305
	mov		bx, 0x031F
	int		0x16
	mov 	bh, [game_start_flag]
	cmp 	bh, 3
	je 		game_start_screen
									

game_loop:
	call	clear_screen					; clear the screen
	push	word [snake_pos] 				; save snake head position for later
	mov		ah, 0x01						; check if key available
	int		0x16
	jz		done_clear						; if not, move on
	mov		ah, 0x00						; if the was a key, remove it from buffer
	int		0x16
	jmp		update_snakepos
done_clear:
	mov		al, [last_move]					; no keys, so we use the last one
update_snakepos:
	cmp		al, 'a'
	je		left
	cmp		al, 's'
	je		down
	cmp		al, 'd'
	je		right
	cmp		al, 'w'
	jne		done_clear
up:
	dec		byte [snake_y_pos]
	jmp		move_done					 	; jump away
left:
	dec		byte [snake_x_pos]
	jmp		move_done		 				; jump away
right:
	inc		byte [snake_x_pos]
	jmp		move_done		 				; jump away
down:
	inc		word [snake_y_pos]
move_done:
	mov		[last_move], al					; save the direction
	mov		si, snake_body_pos 				; prepare body shift
	pop		ax 								; restore read position into ax for body shift
update_body:
	mov		bx, [si]						; get element of body into bx
	test	bx, bx							; check if zero (not a part of the body)
	jz		done_update						; if zero, done. Otherwise
	mov		[si], ax						; move the data from ax, into current position
	add		si, 2							; increment pointer by two bytes
	mov		ax, bx							; save bx into ax for next loop
	jmp		update_body						; loop
done_update:
	cmp		byte [grow_snake_flag], 1 		; snake should grow?
	je		update_apple				; if not: jump to add_zero_snake						
	cmp		byte [grow_snake_flag], 2
	je		update_lemon
	jmp		add_zero_snake
update_apple:
	mov		word [si], ax					; save the last element at the next position
	mov		byte [grow_snake_flag], 0 		; disable grow_snake_flag
	add		si, 2	
	ret
update_lemon:
	mov		word [si], ax
	add		si, 2
	mov 	word [si], ax
	add		si, 2
	mov		word [si], ax					; save the last element at the next position
	mov		byte [grow_snake_flag], 0 		; disable grow_snake_flag
	add		si, 2	
	ret
add_zero_snake:
	mov		word [si], 0x0000
print_stuff:
	xor		dx, dx							; set pos to 0x0000
	call	move_cursor						; move cursor
	mov		si, score_msg					; prepare to print score string
	call	print_string 
	mov		ax, [score]						; move the score into ax
	call	print_int						; print it
    mov 	si, instructions				; move the instructins into si
    call 	print_string 					; print it
	mov		dx, [apple_pos] 				; set dx to the food position
	call	move_cursor						; move cursor there
	mov		al, 'M'
	call	print_char	
	mov		dx, [orange_pos] 			; set dx to the food position
	call	move_cursor						; move cursor there
	mov		al, 'O'							; use 'P' as pineaple  symbol
	call	print_char						; print food
	mov 	dx, [lemon_pos]
	call 	move_cursor
	mov 	al, 'L'
	call 	print_char
	mov		dx, [snake_pos]					; set dx to the snake head position
	call	move_cursor						; move there
	mov		al, '@'							; use '>' as snake head symbol
	call	print_char						; print it
	mov		si, snake_body_pos 				; prepare to print snake body
snake_body_print_loop:
	lodsw									; load position from the body, and increment si
	test	ax, ax							; check if position is zero
	jz		check_collisions 				; if it was zero, move out of here
	mov		dx, ax							; if not, move the position into dx
	call	move_cursor						; move the cursor there
	mov		al, '-'							; use '-' as the snake body symbol
	call	print_char						; print it
	jmp		snake_body_print_loop 			; loop

check_collisions:
	mov		bx, [snake_pos]					; move the snake head position into bx
	cmp		bh, 25							; check if we are too far down
	jge		game_over_hit_wall 				; if yes, jump
	cmp		bh, 0							; check if we are too far up
	jl		game_over_hit_wall 				; if yes, jump
	cmp		bl, 80 							; check if we are too far to the right
	jge		game_over_hit_wall 				; if yes, jump
	cmp		bl, 0							; check if we are too far to the left
	jl		game_over_hit_wall 				; if yes, jump
	mov		si, snake_body_pos 				
move_snake:
	lodsw									; load position of snake body, and increment si
	cmp		ax, bx							; check if head position = body position
	or		ax, ax							; check if position is 0x0000 (we are done searching)
	jne		move_snake 						; if not, loop
no_collision:
	mov		ax, [snake_pos]					; load snake head position into ax
	cmp		ax, [apple_pos]					; check if we are on the apple
	je		apple_collision
	cmp 	ax, [lemon_pos]
	je		lemon_collision
	cmp		ax, [orange_pos]
	je 		orange_collision
	jmp		game_loop_continued 			; if no, then we continue
apple_collision:
	inc		word [score]					; if we were on an apple, increment score by one
	mov		ax, [score]
	cmp		ax, 15
	jge		game_over_win	
	mov		bx, 24							; set max value for random call (y-val - 1)
	call	rand							; generate random value
	push	dx								; save it on the stack
	mov		bx, 78 							; set max value for random call
	call	rand							; generate random value
	pop		cx								; restore old random into cx
	mov		dh, cl							; move old value into high bits of new
	mov		[apple_pos], dx					; save the position of the new random food
	mov		byte [grow_snake_flag], 1 		; make sure snake grows
	ret
lemon_collision:
	inc		word [score]					; if we were on an apple, increment score three times
	inc		word [score]
	inc		word [score]
	mov		ax, [score]
	cmp		ax, 15
	jge		game_over_win
	mov		bx, 24							; set max value for random call (y-val - 1)
	call	rand							; generate random value
	push	dx								; save it on the stack
	mov		bx, 78 							; set max value for random call
	call	rand							; generate random value
	pop		cx								; restore old random into cx
	mov		dh, cl							; move old value into high bits of new
	mov		[lemon_pos], dx					; save the position of the new random food
	mov		byte [grow_snake_flag], 2 		; make sure snake grows
	ret
orange_collision:
	dec		word [score]					; if we were on an apple, increment score by one
	mov		bx, 24							; set max value for random call (y-val - 1)
	call	rand							; generate random value
	push	dx								; save it on the stack
	mov		bx, 78 							; set max value for random call
	call	rand							; generate random value
	pop		cx								; restore old random into cx
	mov		dh, cl							; move old value into high bits of new
	mov		[orange_pos], dx				; save the position of the new random food
	mov		byte [grow_snake_flag], 3 		; make sure snake doesnt grows
	ret 
game_loop_continued:
	mov		cx, 0x0002						; Sleep for 0,15 seconds (cx:dx)
	mov		dx, 0x49F0						; 0x000249F0 = 150000
	mov		ah, 0x86
	int		0x15							; Sleep
	jmp		game_loop						; loop

game_start_screen:
	call	clear_screen
	mov		si, start_msg
	call	print_string
	mov		byte [game_start_flag], 4
	jmp wait_for_r

game_over_win:
	push	win_msg
	jmp		game_over

game_over_hit_wall:
	push	wall_msg

game_over:
	call	clear_screen
	pop si
	call	print_string
	mov		si, retry_msg
	call	print_string

wait_for_r:
	mov		ah, 0x00
	int		0x16
	cmp		al, 'r'
	jne		wait_for_r
	mov		word [snake_pos], 0x0F0F
	and		word [snake_body_pos], 0
	and		word [score], 0
	mov		byte [last_move], 'd'
	jmp		game_loop

; SCREEN FUNCTIONS ------------------------------------------------------------
clear_screen:
	mov		ax, 0x0700						; clear entire window (ah 0x07, al 0x00)
	mov		bh, 0xFC						; light red on black
	xor		cx, cx							; top left = (0,0)
	mov		dx, 0x1950						; bottom right = (25, 80)
	int		0x10
	xor		dx, dx							; set dx to 0x0000
	call	move_cursor						; move cursor
	ret

move_cursor:
	mov		ah, 0x02						; move to (dl, dh)
	xor		bh, bh							; page 0	
	int 	0x10
	ret

print_string_loop:
	call 	print_char
print_string:								; print the string pointed to in si
	lodsb									; load next byte from si
	test	al, al							; check if high bit is set (end of string)
	jns		print_string_loop				; loop if high bit was not set

print_char:									; print the char at al
	and		al, 0x7F						; unset the high bit
	mov		ah, 0x0E
	int		0x10
	ret

print_int:									; print the int in ax
	push	bp								; save bp on the stack
	mov		bp, sp							; set bp = stack pointer

push_digits:
	xor		dx, dx							; clear dx for division
	mov		bx, 10							; set bx to 10
	div		bx								; divide by 10
	push	dx								; store remainder on stack
	test	ax, ax							; check if quotient is 0
	jnz 	push_digits						; if not, loop

pop_and_print_digits:
	pop		ax								; get first digit from stack
	add		al, '0'							; turn it into ascii digits
	call	print_char						; print it
	cmp		sp, bp							; is the stack pointer is at where we began?
	jne		pop_and_print_digits 			; if not, loop
	pop		bp								; if yes, restore bp
	ret 
; UTILITY FUNCTIONS -----------------------------------------------------------
rand:										; random number between 1 and bx. result in dx
	mov		ah, 0x00
	int		0x1A							; get clock ticks since midnight
	mov		ax, dx							; move lower bits into ax for division
	xor		dx, dx							; clear dx
	div		bx								; divide ax by bx to get remainder in dx
	inc		dx
	ret
	
; MESSAGES (Encoded as 7-bit strings. Last byte is an ascii value with its
; high bit set ----------------------------------------------------------------
retry_msg db '! press r to retr', 0xF9 		; y
wall_msg db 'you hit the wall!', 0xEC 				; l
score_msg db 'Score:', 0xA0 				; space
instructions db ' Use W (up) A (left) S(down) D(right) to control', 0xA0 ; space
start_msg db 'Welcome to Apple eater! Press R to start', 0xA0; space
win_msg db 'Congrats, you won!', 0xA0; space

; VARIABLES -------------------------------------------------------------------
grow_snake_flag db 00
apple_pos dw 0x0D0D
orange_pos dw 0x0D1D
lemon_pos dw 0x0D2D
score dw 1
last_move db 'd'
win_score db '15'
game_start_flag db 3
snake_pos:
	snake_x_pos db 0x0F
	snake_y_pos db 0x0F
    snake_body_pos dw 0x0000

times 2048 - ($-$$) db 0
