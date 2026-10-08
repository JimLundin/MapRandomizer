; Foreign items: items that belong to another game (e.g. another player's world in a multiworld).
;
; A foreign item looks and behaves like a collectible item: it is visible, and picking it up sets the location's
; item bit (the PLM room argument), so it stays collected and shows as collected on the map. It gives Samus
; nothing. Instead of the fanfare and message box, the pickup calls `foreign_item_hook` with the location's item bit
; in A. By default the hook only plays a sound; a ROM that knows what the item is (e.g. a multiworld patch) replaces
; the hook with a JML to its own routine.
;
; The item PLMs are placed by patch.rs at locations listed in the randomization's `foreign_items`.

lorom

!bank_84_free_space_start = $84F300
!bank_84_free_space_end = $84F380
!bank_84_free_space2_start = $84F690
!bank_84_free_space2_end = $84F6D0
!bank_85_free_space_start = $85A050
!bank_85_free_space_end = $85A060

!foreign_item_gfx = $B800             ; bank $89 (written by patch.rs)

org !bank_84_free_space_start
; These PLM entries must be at the addresses that patch.rs uses, starting at $84F300
dw $EE64, foreign             ; PLM $F300 (foreign item)
dw $EE64, foreign_orb         ; PLM $F304 (foreign item, chozo orb)
dw $EE8E, foreign_sce         ; PLM $F308 (foreign item, scenery shot block)

;;; Instruction list - PLM $F300 (foreign item)
foreign:
    dw $8764, !foreign_item_gfx            ; Load item PLM GFX
    db $00, $00, $00, $00, $00, $00, $00, $00
    dw $887C, .end                         ; Go to end if the room argument item is set
    dw $8A24, .triggered                   ; Set link instruction for when triggered
    dw $86C1, $DF89                        ; Pre-instruction = go to link instruction if triggered
.animate:
    dw $E04F                               ; Draw item frame 0
    dw $E067                               ; Draw item frame 1
    dw $8724, .animate                     ; Go to animate
.triggered:
    dw $8899                               ; Set the room argument item
    dw collect_foreign                     ; Call the foreign item hook
.end:
    dw $8724, $DFA9                        ; Go to $DFA9

;;; Instruction list - PLM $F304 (foreign item, chozo orb)
foreign_orb:
    dw $8764, !foreign_item_gfx            ; Load item PLM GFX
    db $00, $00, $00, $00, $00, $00, $00, $00
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
    dw collect_foreign                     ; Call the foreign item hook
.end:
    dw $0001, $A2B5
    dw $86BC                               ; Delete

; Instruction: call the foreign item hook, with the room argument (the location's item bit) in A.
collect_foreign:
    phx
    phy
    lda $1DC7,x
    jsl foreign_item_hook
    ply
    plx
    rts

assert pc() <= !bank_84_free_space_end

org !bank_84_free_space2_start
;;; Instruction list - PLM $F308 (foreign item, scenery shot block)
foreign_sce:
    dw $8764, !foreign_item_gfx            ; Load item PLM GFX
    db $00, $00, $00, $00, $00, $00, $00, $00
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
    dw collect_foreign                     ; Call the foreign item hook
.end:
    dw $8A2E, $E032                        ; Call $E032 (empty item shot block reconcealing)
    dw $8724, .start                       ; Go to start

assert pc() <= !bank_84_free_space2_end

org !bank_85_free_space_start
; Called (JSL) when a foreign item is picked up, with A = the location's item bit, data bank $84.
; Replace the first four bytes with a JML to change what happens.
foreign_item_hook:
    lda #$0037                             ; Click sound (sound library 1)
    jsl $809049
    rtl

assert pc() <= !bank_85_free_space_end
