; Foreign items: items that belong to another game (e.g. another player's world in a multiworld).
;
; A foreign item looks and behaves like a collectible item: it is visible, and picking it up sets the location's
; item bit (the PLM room argument), so it stays collected and shows as collected on the map. It gives Samus
; nothing. The pickup calls `foreign_item_hook` with the location's item bit in A (by default it does nothing; a ROM
; that knows more about the item, e.g. a multiworld patch, replaces it with a JML to its own routine), then plays the
; item fanfare (or, with fanfares off, a sound effect) and shows the item's message, if it has one.
;
; Each class (progression, useful, filler) has its own graphics: a four-colour orb, a blue gem, a grey pebble.
;
; patch.rs places the item PLMs at the locations listed in the randomization's `foreign_items`, and describes them
; in `foreign_items_table`: for each item, a word with the item bit (bits 0-9), the class (bits 12-13: 0
; progression, 1 useful, 2 filler) and the number of message rows (bits 14-15: 0 to 2), then two rows of 26 message
; box tile numbers (dialog_chars.tbl and the HUD digits $00-$09, without their attributes); a word $FFFF ends the
; table. The message box is extended_msg_boxes.asm's message $30.

lorom

incsrc "constants.asm"

!bank_84_free_space_start = $84F300
!bank_84_free_space_end = $84F380
!bank_84_free_space2_start = $84F690
!bank_84_free_space2_end = $84F6D0
!bank_85_free_space_start = $85A050
!bank_85_free_space_end = $85A100
!bank_94_free_space_start = $94B1B0
!bank_94_free_space_end = $94B400

!foreign_items_table = $83C000        ; written by patch.rs, up to $83D540
!foreign_item_message = $7EF4E4       ; offset in foreign_items_table of the item whose message is shown
!message_row_chars = 26
!message_entry_size = 54             ; 2 + 2 rows * !message_row_chars


org !bank_84_free_space_start
; These PLM entries must be at the addresses that patch.rs uses, starting at $84F300
dw $EE64, foreign             ; PLM $F300 (foreign item)
dw $EE64, foreign_orb         ; PLM $F304 (foreign item, chozo orb)
dw $EE8E, foreign_sce         ; PLM $F308 (foreign item, scenery shot block)

;;; Instruction list - PLM $F300 (foreign item)
foreign:
    dw load_foreign_gfx                    ; Load item PLM GFX, of the item's class
    dw $887C, .end                         ; Go to end if the room argument item is set
    dw $8A24, .triggered                   ; Set link instruction for when triggered
    dw $86C1, $DF89                        ; Pre-instruction = go to link instruction if triggered
.animate:
    dw $E04F                               ; Draw item frame 0
    dw $E067                               ; Draw item frame 1
    dw $8724, .animate                     ; Go to animate
.triggered:
    dw $8899                               ; Set the room argument item
    dw pickup_foreign                      ; Pick up the foreign item
.end:
    dw $8724, $DFA9                        ; Go to $DFA9

;;; Instruction list - PLM $F304 (foreign item, chozo orb)
foreign_orb:
    dw load_foreign_gfx                    ; Load item PLM GFX, of the item's class
    dw $887C, .end                         ; Go to end if the room argument item is set
    dw $8A2E, $DFAF                        ; Call $DFAF (item orb)
    dw $8A2E, $DFC7                        ; Call $DFC7 (item orb burst)
    dw $8A24, .triggered                   ; Set link instruction for when triggered
    dw $86C1, $DF89                        ; Pre-instruction = go to link instruction if triggered
    dw $874E                               ; Timer = 16h
    db $16
.animate:
    dw $E04F                               ; Draw item frame 0
    dw $E067                               ; Draw item frame 1
    dw $8724, .animate                     ; Go to animate
.triggered:
    dw $8899                               ; Set the room argument item
    dw pickup_foreign                      ; Pick up the foreign item
.end:
    dw $0001, $A2B5
    dw $86BC                               ; Delete

; Instruction: $8764 (load item PLM GFX) with the arguments of the item's class.
load_foreign_gfx:
    jsl foreign_item_gfx_args
    phy
    tay
    jsr $8764
    ply
    rts

; Instruction: the pickup.
pickup_foreign:
    phx
    phy
    jsl foreign_item_pickup
    ply
    plx
    rts

; Arguments of instruction $8764 for each class (foreign_item_gfx_args_by_class): graphics in bank $89, written by
; patch.rs, and the palette of each tile (top left, top right, bottom left, bottom right) in each frame.
gfx_args_progression:                  ; the orb's quarters: gold, blue, pink, green, turning between the frames
    dw $B800 : db $00, $03, $02, $01, $02, $00, $01, $03
gfx_args_useful:                       ; blue
    dw $B900 : db $03, $03, $03, $03, $03, $03, $03, $03

assert pc() <= !bank_84_free_space_end

org !bank_84_free_space2_start
;;; Instruction list - PLM $F308 (foreign item, scenery shot block)
foreign_sce:
    dw load_foreign_gfx                    ; Load item PLM GFX, of the item's class
.start:
    dw $8A2E, $E007                        ; Call $E007 (item shot block)
    dw $887C, .end                         ; Go to end if the room argument item is set
    dw $8A24, .triggered                   ; Set link instruction for when triggered
    dw $86C1, $DF89                        ; Pre-instruction = go to link instruction if triggered
    dw $874E                               ; Timer = 16h
    db $16
.animate:
    dw $E04F                               ; Draw item frame 0
    dw $E067                               ; Draw item frame 1
    dw $873F, .animate                     ; Decrement timer and go to animate if non-zero
    dw $8A2E, $E020                        ; Call $E020 (item shot block reconcealing)
    dw $8724, .start                       ; Go to start
.triggered:
    dw $8899                               ; Set the room argument item
    dw pickup_foreign                      ; Pick up the foreign item
.end:
    dw $8A2E, $E032                        ; Call $E032 (empty item shot block reconcealing)
    dw $8724, .start                       ; Go to start

gfx_args_filler:                       ; palette 1's greys
    dw $BA00 : db $01, $01, $01, $01, $01, $01, $01, $01

assert pc() <= !bank_84_free_space2_end

org !bank_85_free_space_start
; Called (JSL) when a foreign item is picked up, with A = the location's item bit, data bank $84.
; Replace the first four bytes with a JML to change what happens.
foreign_item_hook:
    rtl
    nop : nop : nop

; Message box $30 (jumped to from extended_msg_boxes.asm, in place of $85:8241): the foreign item message
; [!foreign_item_message]. Like a small message box ($85:8289, $85:82B8, $85:8436), with the rows from the table.
assert pc() == !foreign_item_message_box
foreign_item_message_box:
    ldx #$0000
.top:                                  ; top border
    lda $8040,x
    sta $7E3200,x
    inx : inx
    cpx #$0040
    bne .top
    jsr $8136                          ; as $85:82B8
    jsl $808F0C
    jsl $8289EF
    rep #$30
    lda #$0070 : sta $05A6
    lda #$007C : sta $05A4
    stz $05A2
    ldx #$0000
    txa
.clear:
    sta $7E3000,x
    inx : inx
    cpx #$00E0
    bne .clear
    jsl foreign_item_message_rows
    txa                                ; DMA size: the box with its borders
    clc
    adc #$0040
    sta $09
    ldy #$0000
.bottom:                               ; bottom border
    lda $8040,y
    sta $7E3200,x
    inx : inx : iny : iny
    cpy #$0040
    bne .bottom
    jsr $8436                          ; small message box
    rts

assert pc() <= !bank_85_free_space_end

org !bank_94_free_space_start
; The table entry of PLM X's item: X = its offset in foreign_items_table, carry set if there is one.
find_entry:
    lda $1DC7,x                        ; the item bit
    pha
    ldx #$0000
.loop:
    lda.l !foreign_items_table,x
    cmp #$FFFF
    beq .none
    and #$03FF
    cmp $01,s
    beq .found
    txa : clc : adc.w #!message_entry_size : tax
    bra .loop
.found:
    pla
    sec
    rts
.none:
    pla
    clc
    rts

; The address in bank $84 of the instruction $8764 arguments for PLM X's item (JSL; X = PLM index, data bank $84).
; X and Y are kept.
foreign_item_gfx_args:
    phx
    jsr find_entry
    lda #$0000                         ; progression, if not found
    bcc .class
    lda.l !foreign_items_table,x
    xba
    lsr : lsr : lsr : lsr
    and #$0003
    asl
.class:
    tax
    lda.l foreign_item_gfx_args_by_class,x
    plx
    rtl

foreign_item_gfx_args_by_class:
    dw gfx_args_progression, gfx_args_useful, gfx_args_filler

; The pickup (JSL; X = PLM index, data bank $84).
foreign_item_pickup:
    php
    rep #$30
    lda $1DC7,x
    jsl foreign_item_hook              ; with A = the item bit
    jsr find_entry
    bcc .no_message
    lda.l !foreign_items_table,x
    and #$C000
    beq .no_message
    txa
    sta.l !foreign_item_message
    lda.l $848BF2
    cmp #$00A9                         ; changed by itemsounds.asm (fanfares off)
    bne .sound
    phx                                ; as PLM instruction $84:8BDD with the item fanfare (music track 2)
    ldx #$000E
.clear_music_queue:
    stz $0619,x
    stz $0629,x
    dex : dex
    bpl .clear_music_queue
    plx
    lda $0639 : sta $063B
    lda #$0000 : sta $063F : sta $063D
    lda #$0002
    jsl $808FC1
    bra .show
.sound:
    lda #$0002                         ; as itemsounds.asm: the message box doesn't restart the music
    sta $05D7
    jsr click
.show:
    lda #$0030
    jsl $858080
    plp
    rtl
.no_message:
    jsr click
    plp
    rtl

click:
    lda #$0037                         ; Click sound (sound library 1)
    jsl $809049
    rts

; The message rows, after the top border of the message box tilemap ($7E:3240); X = the end of the rows.
foreign_item_message_rows:
    lda.l !foreign_item_message
    tax
    lda.l !foreign_items_table,x       ; rows in bits 14-15
    xba
    lsr : lsr : lsr : lsr : lsr : lsr
    and #$0003
    sta $16
    txa
    inc : inc
    sta $12                            ; the next tile number in the table
    ldx #$0040
.row:
    lda #$000E                         ; box sides
    sta $7E3200,x : sta $7E3202,x : sta $7E3204,x
    txa : clc : adc #$0006 : tax
    lda.w #!message_row_chars
    sta $18
.char:
    phx
    ldx $12
    lda.l !foreign_items_table,x
    plx
    and #$00FF
    cmp #$000A
    bcs .letter
    ora #$3800                         ; digits (the HUD's), in the palette that draws them like the letters
    bra .put
.letter:
    ora #$2C00
.put:
    sta $7E3200,x
    inx : inx
    inc $12
    dec $18
    bne .char
    lda #$000E
    sta $7E3200,x : sta $7E3202,x : sta $7E3204,x
    txa : clc : adc #$0006 : tax
    dec $16
    bne .row
    rtl

assert pc() <= !bank_94_free_space_end
