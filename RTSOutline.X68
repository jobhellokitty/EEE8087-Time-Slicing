*-----------------------------------------------------------
* Title      : RTS
* Written by : JNC
* Date       : Dec 23
* Description: Outline runtime system 
*-----------------------------------------------------------
                                ;system call equates
sys     equ     0               ; system call trap (trap 0)
syscr   equ     1               ; create new task
sysdel  equ     2               ; delete task
syswtmx equ     3               ; wait on mutex
syssgmx equ     4               ; signal mutex
sysinmx equ     5               ; initialise mutex 
syswttm equ     6               ; wait on timer

usrcode equ     $1000           ;address of user task 0
usrstk  equ     $8000           ;address of user stack

ntcblst equ     8               ;number of records in tcb list

tcb     org     0               ;tcb record
tcbd0   ds.l    1               ; D register save
tcbd1   ds.l    1
tcbd2   ds.l    1
tcbd3   ds.l    1
tcbd4   ds.l    1
tcbd5   ds.l    1
tcbd6   ds.l    1
tcbd7   ds.l    1
tcba0   ds.l    1               ; A register save
tcba1   ds.l    1
tcba2   ds.l    1
tcba3   ds.l    1
tcba4   ds.l    1
tcba5   ds.l    1
tcba6   ds.l    1
tcba7   ds.l    1
tcbsr   ds.l    1               ; SR (status reg) save
tcbpc   ds.l    1               ; PC save          
tcbnext ds.l    1               ; link to next record
tcbused ds.l    1               ; record in use flag
tcbwtim ds.l    1               ; timer wait expiry time
tcblen  equ     *               ; length of tcb record

;******************************************************************************
rts                                     ;RUNTIME SYSTEM
;******************************************************************************

;******************************************************************************
                                        ;INTERRUPT VECTORS
;******************************************************************************

        org     0
        
        dc.l    usrstk                  ; initial SP
        dc.l    res                     ; reset
        ds.b    $5C
        dc.l    fltint                  ; interrupt 1 (timer)
        ds.b    $18
        dc.l    flsint                  ; trap 0 (system call)
        
;*******************************************************************************        
res                                     ;RESET
;*******************************************************************************

        
;*******************************************************************************        
flih                                    ;FIRST-LEVEL INTERRUPT HANDLER
;*******************************************************************************

fltint                                  ;ENTRY FROM TIMER INTERRUPT  
        move.l  d0,d0sav                ;save D0
        move.l  #$0,d0                  ;set id = 0
        move.l  d0,id
        move.l  d0sav,d0                ;restore D0
        bra     fl1  

flsint                                  ;ENTRY FROM TRAP (SOFTWARE INTERRUPT)
        or      #%0000011100000000,sr   ;disable hardware interrupts
        move.l  d0,id                   ;store id
        bra     fl1
       
fl1     move.l  a0,a0sav                ;save working reg
        
        move.l  rdytcb,a0               ;A0 ^ 1st ready tcb (ie running tcb)
            
        move.l  d0,tcbd0(a0)            ;store registers
        move.l  d1,tcbd1(a0)       
        move.l  d2,tcbd2(a0)
        move.l  d3,tcbd3(a0) 
        move.l  d4,tcbd4(a0)
        move.l  d5,tcbd5(a0)       
        move.l  d6,tcbd6(a0)
        move.l  d7,tcbd7(a0)
        move.l  a0sav,d0 
        move.l  d0,tcba0(a0)
        move.l  a1,tcba1(a0)       
        move.l  a2,tcba2(a0)
        move.l  a3,tcba3(a0) 
        move.l  a4,tcba4(a0)
        move.l  a5,tcba5(a0)       
        move.l  a6,tcba6(a0)

        move    (sp),d0                 ;pop and store SR
        add.l   #2,sp              
        move.l  d0,tcbsr(a0)
        
        move.l  (sp),d0                 ;pop and store PC
        add.l   #4,sp
        move.l  d0,tcbpc(a0)
        
        move.l  a7,tcba7(a0)            ;store SP 
        
;******************************************************************************
serv                                    ;SERVICE ROUTINES
;******************************************************************************

        
;*******************************************************************************
sched                                   ;SCHEDULER  
;*******************************************************************************


;*******************************************************************************        
disp                                    ;DISPATCHER 
;*******************************************************************************

        move.l  rdytcb,a0               ;A0 ^ new running tcb
        move.l  tcbd1(a0),d1            ;restore registers      
        move.l  tcbd2(a0),d2
        move.l  tcbd3(a0),d3 
        move.l  tcbd4(a0),d4
        move.l  tcbd5(a0),d5       
        move.l  tcbd6(a0),d6
        move.l  tcbd7(a0),d7
        move.l  tcba1(a0),a1       
        move.l  tcba2(a0),a2
        move.l  tcba3(a0),a3 
        move.l  tcba4(a0),a4
        move.l  tcba5(a0),a5       
        move.l  tcba6(a0),a6
        move.l  tcba7(a0),a7

        sub.l   #4,sp                   ;push PC
        move.l  tcbpc(a0),d0            
        move.l  d0,(sp)   

        sub.l   #2,sp           
        move.l  tcbsr(a0),d0            ;push SR
        move    d0,(sp)
        
        move.l  tcbd0(a0),d0            ;restore remaining registers
        move.l  tcba0(a0),a0
        
        rte                             ;return

;*******************************************************************************
                                        ;RTS variables
;*******************************************************************************

tcblst  ds.b    tcblen*ntcblst          ;tcb list
rdytcb  ds.l    1                       ;^ ready tcb list
wttcb   ds.l    1                       ;^ waiting tcb
a0sav   ds.l    1                       ;A0 temporary save
d0sav   ds.l    1                       ;D0 temporary save
id      ds.l    1                       ;function id
time    ds.l    1                       ;system time
        
;*******************************************************************************
                                        ;USER APPLICATION TASKS
;*******************************************************************************
        
        org     usrcode

led     equ     $e00010         ;led
sw      equ     $e00014         ;switch

t0:                             ;TASK 0
        move.l  #syscr,d0       ;start task 1
        move.l  #t1,d1
        move.l  #$4000,d2
        trap    #sys        
                                ;repeat
t00:    move.l  #$01,d1         ;  set led 0
        move.b  d1,led
        
        bra     t00
        
t1:                             ;TASK 1  
                                ;repeat
        move.l  #$02,d0         ;  set led 1
        move.b  d0,led
       
        bra     t1

        END    res  











































































































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
