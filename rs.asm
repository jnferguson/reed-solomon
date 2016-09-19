%define FIELD_SIZE 0x08
%define FIELD_MASK 0x07
%define PRIMITIVE_ROOT 0x03

STRUC polynomial_t
	.order:		resb 1
	.coefficients:	resb 8
	.size:
ENDSTRUC

STRUC galois_t
	.alpha_to:	resb FIELD_SIZE
	.index_of:	resb FIELD_SIZE
	.remainder_tbl:	resb 7*8*7
	.size:
ENDSTRUC

STRUC vars_t
	.generator:		resd 1
	.field:			resd 1
	.test:			resd 1
	.size:
ENDSTRUC

STRUC dmvars_t
	.denominator:		resd 1
	.denom_order:		resb 1
	.numerator:		resd 1
	.num_order:		resb 1
	.field:			resb galois_t.size
	.remainder:		resb polynomial_t.size 
	.scratch:		resb polynomial_t.size
	.rem_order:		resb 1
	.scratch_order:		resb 1
	.factor:		resb 1
	.value:			resb 1
	.coef_denominator	resb 1
	.i:			resb 1
	.j:			resb 1
	.size:
ENDSTRUC

SECTION .text
	global _start

_start:
	push	ebp
	mov	ebp, esp
	sub	esp, vars_t.size
	lea	esi, [esp]
	mov	edi, esi
	mov	ecx, vars_t.size
	xor	eax, eax
	call	_zero
	mov	edx, eax			; edx = vars_t

	mov	ecx, galois_t.size
	sub	esp, ecx
	lea	edi, [esp]
	call	_zero
	lea	ecx, [edx + vars_t.field]
	mov	dword [ecx], eax

	pushad
	xor	eax, eax
	xor	ebx, ebx
	;xor	edx, edx
	xor	ebp, ebp
	
	inc	eax
	mov	edx, dword [edx + vars_t.field]
	lea	edi, [edx + galois_t.alpha_to]
	lea	esi, [edx + galois_t.index_of]
	xor	ecx, ecx
	mov	ebp, FIELD_MASK
	xor	edx, edx

	init_field_cont:
		mov	byte [edi + ecx], al		; alpha_to[idx] = al
		movzx	edx, byte [edi + ecx]		; edx = alpha_to[al]
		mov	byte [esi + edx], cl		; index_of[edx] = cl

		shl	eax, 0x01
		mov	edx, eax
		and	edx, FIELD_SIZE
		inc	ecx
		cmp	ecx, FIELD_MASK
		jge	field_fin
		test	edx, edx
		je	init_field_cont
		xor	eax, PRIMITIVE_ROOT
		and	eax, FIELD_MASK
		jmp	init_field_cont

	field_fin:
		mov	byte [esi], FIELD_MASK
		popad

	sub	esp, polynomial_t.size
	lea	edi, [esp]
	mov	ecx, polynomial_t.size
	call	_zero
	mov	dword [edx + vars_t.generator], edi
	lea	esi, [edi + polynomial_t.coefficients]
	mov	byte [esi], 0x03
	inc	esi
	mov	byte [esi], 0x06
	inc	esi
	mov	byte [esi], 0x01
	lea	esi, [edi + polynomial_t.order]
	mov	byte [esi], 0x03


	sub	esp, polynomial_t.size
	lea	edi, [esp]
	mov	ecx, polynomial_t.size
	call	_zero
	mov	dword [edx + vars_t.test], edi

	xor	ebx, ebx
	inc	ebx

	; for (ebx = 1; ebx < FIELD_MASK; ebx++) {
	remainder_tbl_outer_loop:
		cmp	ebx, FIELD_MASK
		jge	remainder_tbl_fin
		xor	eax, eax
		
		; for (eax = 0; eax < FIELD_MASK; eax++) {
		remainder_tbl_inner_loop:
			cmp 	eax, FIELD_MASK
			jge	remainder_tbl_inner_fin	
		
			; memset(test, 0, 0x09)	
			push	eax
			mov	edi, dword [edx + vars_t.test]
 			xor	eax, eax
			mov	ecx, 0x09
			rep	stosb
			pop	eax

			; test.order = eax+1
			mov	edi, dword [edx + vars_t.test]
			lea	edi, [edi + polynomial_t.order]
			mov	byte [edi], al
			inc	byte [edi]
	
			; ecx = eax-1
			; test.coefficients[ecx] = ebx
			movzx	ecx, al
			;dec	ecx
			mov	edi, dword [edx + vars_t.test]
			lea	edi, [edi + polynomial_t.coefficients]
			;dec	ecx
			add	edi, ecx
			mov	byte [edi], bl			

			; _divmod(generator,test,field)
			push	eax			
			push	ebx
			mov	eax, dword [edx + vars_t.generator]
			mov	ebx, dword [edx + vars_t.test]
			mov	ecx, dword [edx + vars_t.field]
			call	_divmod
			lea	esi, [eax + polynomial_t.coefficients]
			pop	ebx
			pop	eax
			push	esi
			push	edx
			push	eax

			; edi = remainder_tbl
			; row = (ebx-1)*FIELD_SIZE*FIELD_MASK
			; edi += row
			lea	edi, [ecx + galois_t.remainder_tbl]
			mov	ecx, ebx
			dec	ecx
			mov	eax, FIELD_SIZE*FIELD_MASK
			mul	ecx
			add	edi, eax
			pop	eax
			
			; col = (eax-1)*FIELD_SIZE
			; edi += row
			mov	ecx, eax
			;dec	eax
			push	eax
			mov	eax, FIELD_SIZE
			mul	ecx
			add	edi, eax
			pop	eax
			pop	edx

			; memcpy(&remainder_tbl[((ebx-1)*(FIELD_SIZE*FIELD_MASK))+((eax-1)*FIELD_SIZE)], divmod_retval.coefficients, 8)
			pop	esi
			mov	ecx, FIELD_SIZE
			rep	movsb
			inc	eax
			jmp	remainder_tbl_inner_loop

		remainder_tbl_inner_fin:
			inc	ebx
			jmp	remainder_tbl_outer_loop
	remainder_tbl_fin:
		leave
		ret

	lea	esi, [edi + polynomial_t.coefficients]
	add	esi, 0x03
	mov	byte [esi], 0x06
	lea	esi, [edi + polynomial_t.order]
	mov	byte [esi], 0x04		

	mov	eax, dword [edx + vars_t.generator]
	mov	ebx, dword [edx + vars_t.test]
	mov	ecx, dword [edx + vars_t.field]
	call	_divmod	
	
	leave
	ret

_zero:
	pushad
	
	mov	eax, ecx
	xor	edx, edx
	mov	ecx, 0x04
	div	ecx
	push	edx
	push	edi
	mov	ecx, eax
	xor	eax, eax
	rep	stosd

	pop	edi
	pop	ecx			; pop remainder (edx) into ecx
	mov	dword [esp+0x1c], edi	; overwrite eax with the value of the dest pointer
	rep	stosb
	popad
	ret	

_add:
	pusha
	mov	ecx, FIELD_SIZE
	xor	edx, edx
	div	ecx
	movzx	edi, dl
	
	xor	edx, edx
	mov	eax, ebx
	div	ecx
	movzx	eax, dl

	xor	eax, edi
	mov	byte [esp + 0x1c], al
	popa
	ret

_mul:
	pushad
	test	eax, eax
	jz	mul_fin_zero
	test	ebx, ebx
	jz	mul_fin_zero
	mov	ecx, FIELD_SIZE
	xor	edx, edx
	mov	edi, ebx
	mov	esi, FIELD_MASK
	mov	ebx, 0x01

	mul_loop:
	cmp	ebx, esi
	jae	mul_fin			; if (cnt >= 7) goto _gf_mul_fin
	mov 	ebp, edi			; ebp = k
	and 	ebp, ecx			; ebp &= (1 << m)
	test 	ebp, ebp			; if ! ebp 
	je	mul_inner_loop
	xor 	edi, PRIMITIVE_ROOT		; k ^= 0x03 (primitive root)

	mul_inner_loop:		
		mov 	ebp, eax		; ebp = a
		and 	ebp, ebx		; ebp &= b
		test 	ebp, ebp		; if ebp
		je 	mul_inc_loop_ctrs
		xor 	edx, edi		; r ^= k

	mul_inc_loop_ctrs:		
		shl	edi, 1			; k <<= 1
		shl	ebx, 1			; cnt <<= 1
		jmp	mul_loop	
	
	mul_fin:
		mov	eax, edx
		mov	ecx, FIELD_SIZE
		xor	edx, edx
		div	ecx
		mov 	dword [esp+0x1c], edx
		popad
		ret
	mul_fin_zero:
		mov 	dword [esp+0x1c], 0
		popad
		ret

_divmod:
	pushad
	mov	ebp, esp
	sub	esp, dmvars_t.size

	; set the pointers to the denominator and numerator and galois field
	; respectively from the function parameters, which are passed through the registers	
	lea	edx, [esp]
	mov	dword [edx + dmvars_t.denominator], eax
	mov	dword [edx + dmvars_t.numerator], ebx
	mov	dword [edx + dmvars_t.field], ecx

	; if numerator.order < denominator.order ... return (already done)
	movzx	esi, byte [ebx + polynomial_t.order]
	movzx	edi, byte [eax + polynomial_t.order]
	cmp	esi, edi
	jge	divmod_init_vars
	add	esp, dmvars_t.size
	popad
	mov	eax, ebx
	ret

	; initialize the two order variables to the value of the denominators order
	; and the numerators order respectively	
	divmod_init_vars:
		movzx	eax, byte [eax]
		movzx	ebx, byte [ebx]
		lea	esi, [edx + dmvars_t.denom_order]
		mov	byte [esi], al
		lea	esi, [edx + dmvars_t.num_order]
		mov	byte [esi], bl


	; initialize the remainder polynomial to zero
	xor	eax, eax
	lea	edi, [edx + dmvars_t.remainder]
	mov	ecx, 0x09
	call	_zero
	
	; and zero initialize scratch
	xor	eax, eax
	lea	edi, [edx + dmvars_t.scratch]
	mov	ecx, 0x09
	call	_zero
	lea	edi, [edx + dmvars_t.scratch]
	lea	edi, [edi + polynomial_t.order]
	mov	byte [edi], FIELD_SIZE
	lea	edi, [edx + dmvars_t.scratch_order]
	mov	byte [edi], 0x00

	; initialize coef_denominator	
	mov	byte [edx + dmvars_t.coef_denominator], 0x00

;	movzx	esi, byte [edx + dmvars_t.denom_order]
;	movzx	edi, byte [edx + dmvars_t.num_order]
;	cmp	esi, edi
;	jge	divmod_fin
	
	; remainder = numerator
	mov	esi, dword [edx + dmvars_t.numerator]
	lea	esi, [esi + polynomial_t.coefficients]
	lea	edi, [edx + dmvars_t.remainder]
	lea	edi, [edi + polynomial_t.coefficients]
	mov	ecx, 0x09
	rep	movsb
	lea	edi, [edx + dmvars_t.remainder]
	mov	eax, dword [edx + dmvars_t.numerator]
	movzx	eax, byte [eax + polynomial_t.order]
	lea	edi, [edi + polynomial_t.order]
	mov	byte [edi], al
	lea	edi, [edx + dmvars_t.rem_order]
	mov	byte [edi], al
	

	; coef_denominator = index_of[denominator.order()]
	mov	esi, dword [edx + dmvars_t.denominator]
	lea	esi, [esi + polynomial_t.order]
	movzx	ebx, byte [esi]
	dec	ebx
	mov	esi, dword [edx + dmvars_t.denominator]
	lea	esi, [esi + polynomial_t.coefficients]
	add	esi, ebx
	movzx	ebx, byte [esi]
	mov	ecx, dword [edx + dmvars_t.field]
	lea	ecx, [ecx + galois_t.index_of]
	add	ecx, ebx
	movzx	ecx, byte [ecx]
	mov	byte [esp + dmvars_t.coef_denominator], cl	

	divmod_main_loop:
		; while denom_order <= rem_order
		movzx	eax, byte [edx + dmvars_t.denom_order]
		cmp	al, byte [edx + dmvars_t.rem_order]
		jg	divmod_fin

		; eax = remainder[rem_order-1]
		movzx	eax, byte [edx + dmvars_t.rem_order]
		dec	eax
		lea	ecx, [edx + dmvars_t.remainder]
		lea	ecx, [ecx + polynomial_t.coefficients]
		add	ecx, eax
		movzx	eax, byte [ecx]

		; factor = index_of[remainder[rem_order-1]]
		mov	ecx, dword [edx + dmvars_t.field]
		lea	ecx, [ecx + galois_t.index_of]
		add	ecx, eax
		movzx	eax, byte [ecx]
		lea	ecx, [edx + dmvars_t.factor]
		mov	byte [ecx], al

		; value = 0
		lea	eax, [edx + dmvars_t.value]
		mov	byte [eax], 0x00

		; i = rem_order ? rem_order - 1 : 0
		xor	ebx, ebx
		inc	ebx
		movzx	eax, byte [edx + dmvars_t.rem_order]
		test	eax, eax
		cmovnz	ebx, eax
		dec	ebx
		mov	byte [edx + dmvars_t.i], bl

		; j = scratch_order ? scratch_order - 1 : 0
		xor	ebx, ebx
		inc	ebx
		movzx	eax, byte [edx + dmvars_t.scratch_order]
		test	eax, eax
		cmovnz	ebx, eax
		dec	ebx
		mov	byte [edx + dmvars_t.j], bl
	
		; if 0 == remainder[rem_order-1] value = 0
		movzx	eax, byte [edx + dmvars_t.rem_order]
		dec	eax
		lea	ebx, [edx + dmvars_t.remainder]
		lea	ebx, [ebx + polynomial_t.coefficients]
		add	ebx, eax
		movzx	eax, byte [ebx]
		test	eax, eax
		jnz	divmod_val_nonzero
		lea	eax, [edx + dmvars_t.value]
		mov	byte [eax], 0x00
		jmp	divmod_scratch_start

		; else ....
		divmod_val_nonzero:
			; factor += FIELD_SIZE - coef_denominator
			movzx	eax, byte [edx + dmvars_t.factor]
			movzx	ebx, byte [edx + dmvars_t.coef_denominator]
			mov	ecx, FIELD_SIZE
			sub	eax, ebx
			add	eax, ecx
			; factor %= FIELD_SIZE
			;mov	eax, FIELD_SIZE
			push	edx
			xor	edx, edx
			div	ecx
			movzx	eax, dl
			pop	edx
			mov	byte [edx + dmvars_t.factor], al
			; value = alpha_to[factor]
			mov	ebx, dword [edx + dmvars_t.field]
			lea	ebx, [ebx + galois_t.alpha_to]	
			add	ebx, eax
			movzx	ebx, byte [ebx]
			lea	ecx, [edx + dmvars_t.value]
			mov	byte [ecx], bl
	
		divmod_scratch_start:
			; idx = 0
			xor	ecx, ecx
	
			divmod_scratch_loop:
				; if idx >= FIELD_SIZE
				;	break;
				cmp	ecx, FIELD_SIZE
				jge	divmod_scratch_fin
				; _mul(value, denominator[idx])
				mov	ebx, dword [edx + dmvars_t.denominator]
				lea	ebx, [ebx + polynomial_t.coefficients]
				add	ebx, ecx
				movzx	ebx, byte [ebx]
				movzx	eax, byte [edx + dmvars_t.value]
				call	_mul
				; scratch[idx] = _mul(value,denominatpr[idx])
				lea	ebx, [edx + dmvars_t.scratch]
				lea	ebx, [ebx + polynomial_t.coefficients]
				add	ebx, ecx
				mov	byte [ebx], al 			
				inc	ecx
				jmp	divmod_scratch_loop			

		divmod_scratch_fin:
			mov	ecx, FIELD_SIZE
			lea	eax, [edx + dmvars_t.scratch]
			lea	eax, [eax + polynomial_t.coefficients]
			
			divmod_find_scratch_order:
				dec	ecx
				test	ecx, ecx
				jz	divmod_scratch_order_zero
				cmp	byte [eax+ecx], 0x00
				jnz	divmod_scratch_order_fin
				jmp	divmod_find_scratch_order

			divmod_scratch_order_fin:
			divmod_scratch_order_zero:
				lea	eax, [edx + dmvars_t.scratch]
				lea	eax, [eax + polynomial_t.order]
				mov	byte [eax], cl
				lea	eax, [edx + dmvars_t.scratch_order]
				mov	byte [eax], cl
				lea	eax, [edx + dmvars_t.j]
				mov	byte [eax], cl

			; idx = 0
			xor	ecx, ecx
		
			divmod_remainder_loop:
				; if idx >= FIELD_SIZE
				;	break
				cmp	ecx, FIELD_SIZE
				jge	divmod_remainder_fin
	
				; _sub(remainder[i], scratch[idx])
				lea	eax, [edx + dmvars_t.remainder]
				lea	eax, [eax + polynomial_t.coefficients]
				movzx	esi, byte [edx + dmvars_t.i]
				add	eax, esi
				movzx	eax, byte [eax]
				lea	ebx, [edx + dmvars_t.scratch]
				lea	ebx, [ebx + polynomial_t.coefficients]
				movzx	esi, byte [edx + dmvars_t.j]
				add	ebx, esi
				movzx	ebx, byte [ebx]
				call	_add

				; remainder[i] = _sub(remainder[i], scratch[j])
				lea	ebx, [edx + dmvars_t.remainder]
				lea	ebx, [ebx + polynomial_t.coefficients]
				movzx	esi, byte [edx +dmvars_t.i]
				add	ebx, esi
				mov	byte [ebx], al					

				; i--, j--
				cmp	byte [edx + dmvars_t.i], 0x00
				jne	divmod_sanity_one
				jmp	divmod_remainder_fin

				divmod_sanity_one:
					cmp	byte [edx + dmvars_t.j], 0x00
					je	divmod_remainder_fin
				divmod_sanity_two:
					dec	byte [edx + dmvars_t.i]
					dec	byte [edx + dmvars_t.j]
	
				jmp divmod_remainder_loop
										
		divmod_remainder_fin:
				movzx	eax, byte [edx + dmvars_t.rem_order]	
				dec	eax
				lea	edi, [edx + dmvars_t.rem_order]
				mov	byte [edi], al
				lea	edi, [edx + dmvars_t.remainder]
				lea	edi, [edi + polynomial_t.order]
				mov	byte [edi], al
				lea	edi, [edx + dmvars_t.remainder]
				lea	edi, [edi + polynomial_t.coefficients]
				add	edi, eax
	
				divmod_resize_remainder:
					mov 	byte [edi], 0x00
					inc	eax
					inc	edi
					cmp	eax, FIELD_SIZE
					jge	divmod_main_loop
					jmp	divmod_resize_remainder
	divmod_fin:
		mov	edi, dword [edx + dmvars_t.numerator]
		lea	esi, [edx + dmvars_t.remainder]
		mov	ecx, 0x09
		rep	movsb
		add	esp, dmvars_t.size
		popad
		mov	eax, ebx
		ret
