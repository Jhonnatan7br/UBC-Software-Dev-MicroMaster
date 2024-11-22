;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname |Space Invaders Final First Course|) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
;;Requires
(require 2htdp/universe)
(require 2htdp/image)

;;Constants
(define SCREEN-WIDTH 400)
(define SCREEN-HEIGHT 600)
(define TANK-SPEED 5)
(define MISSILE-SPEED 7)
(define INVADER-SPEED 3)

;;Data Definitions HtDD

;;Tank
; A Tank is represented as an x-coordinate.
; Range: 0 to SCREEN-WIDTH
(define TANK-INITIAL-POS (/ SCREEN-WIDTH 2))
;; Missiles fired by both the tank and invaders need to be distinguished.
;; A Missile is a structure (make-missile x y fired-by)
;; fired-by is a String: either "tank" or "invader"
(define-struct missile (x y fired-by))
;;Invader
; An Invader is a structure (make-invader x y dx dy)
(define-struct invader (x y dx dy))
; x, y: position of the invader
; dx, dy: direction and speed of movement
;; Initial World State
(define-struct world [tank missiles invaders]) ; Removed game-over? field


;;Functions

;;Tank Movement stub
; tank-move : Tank String -> Tank
; Moves the tank left or right based on the key input.
(define (tank-move tank key)
  tank) ; stub
;;Missile movement stub
; missile-move : Missile -> Missile
; Moves the missile upward over time.
(define (missile-move missile)
  missile) ; stub
;;Invader movement stub
; invader-move : Invader -> Invader
; Moves the invader at a 45-degree angle, bouncing off walls.
(define (invader-move invader)
  invader) ; stub


;; Game Display with helpers
; draw-tank : Number -> Image
; Draws the tank at the given x-coordinate.
(define (draw-tank tank-x)
  (place-image
   (overlay/align "center" "bottom"
     ; Tank turret
     (overlay/xy (rectangle 10 30 "solid" "darkgreen") 0 -15  ; Adjust turret position
       ; Tank base
       (overlay/xy (rectangle 50 20 "solid" "green") 0 0
         ; Left track
         (overlay/xy (circle 7 "solid" "black") -15 10
           ; Right track
           (overlay/xy (circle 7 "solid" "black") 15 10
             empty-image))))
     empty-image)
   tank-x (- SCREEN-HEIGHT 40)  ; Adjust the y-coordinate to ensure the tank is visible
   (empty-scene SCREEN-WIDTH SCREEN-HEIGHT)))  ; Use the entire screen as the background

; draw-missiles : List of Missiles -> Image
; Draws all the missiles on the screen.
(define (draw-missiles missiles)
  (cond
    [(empty? missiles) empty-image] ; If there are no missiles, return an empty image
    [else
     (place-image
      (triangle 10 20 "solid" "red") ; Missile as a red triangle
      (missile-x (first missiles)) (missile-y (first missiles)) ; Position the missile
      (draw-missiles (rest missiles)))])) ; Recursive call to draw the rest of the missiles

; draw-invaders : List of Invaders -> Image
; Draws all the invaders on the screen.
(define (draw-invaders invaders)
  (cond
    [(empty? invaders) empty-image] ; If there are no invaders, return an empty image
    [else
     (place-image
      (overlay/align "center" "center"
        (overlay/xy (circle 15 "solid" "lightblue") 0 -10 ; UFO dome
          (overlay/xy (ellipse 40 20 "solid" "gray") 0 0  ; UFO base
            (overlay/xy (circle 5 "solid" "yellow") -15 10 ; Left light
              (overlay/xy (circle 5 "solid" "yellow") 15 10
                empty-image)))) ; Empty image as the innermost background
        empty-image) ; Add empty-image as the background for overlay/align
      (invader-x (first invaders)) (invader-y (first invaders)) ; Position the invader
      (draw-invaders (rest invaders)))])) ; Recursive call to draw the rest of the invaders

; render-world : World -> Image
; Draws the game state, including the tank, missiles, invaders, and a static background.
(define (render-world world)
  (overlay
    (draw-missiles (world-missiles world))  ; Draw the missiles first
    (draw-invaders (world-invaders world))  ; Draw the invaders next
    (draw-tank (world-tank world))))        ; Draw the tank last

;;Initial world statement
(define initial-world
  (make-world TANK-INITIAL-POS
              empty                  ; No missiles at the start
              (list (make-invader 50 0 3 3) ; Sample invader positions
                    (make-invader 150 0 -3 3)
                    (make-invader 250 0 3 -3))))


;; Updated handle-key function
(define (handle-key world key)
  (cond
    [(string=? key "left") 
     (make-world (max 0 (- (world-tank world) TANK-SPEED))
                 (world-missiles world)
                 (world-invaders world))]
    [(string=? key "right") 
     (make-world (min SCREEN-WIDTH (+ (world-tank world) TANK-SPEED))
                 (world-missiles world)
                 (world-invaders world))]
    [(string=? key " ") 
     (make-world (world-tank world)
                 (cons (make-missile (world-tank world) (- SCREEN-HEIGHT 80) "tank") ; Mark the missile as fired by the tank
                       (world-missiles world))
                 (world-invaders world))]
    [else world]))


; update-world : World -> World
; Updates the state of the world on each tick by moving missiles and invaders.
(define (update-world world)
  (make-world (world-tank world)               ; Keep the tank in the same position
              (move-missiles (world-missiles world)) ; Move all missiles
              (move-invaders (world-invaders world)))) ; Move all invaders

; move-missiles : List of Missiles -> List of Missiles
; Moves each missile upward by a fixed speed using recursion.
(define (move-missiles missiles)
  (cond
    [(empty? missiles) empty] ; No missiles left to move
    [else
     (if (< (- (missile-y (first missiles)) MISSILE-SPEED) 0)
         (move-missiles (rest missiles)) ; Remove missile if off-screen
         (cons (make-missile (missile-x (first missiles))  ; Pass x-coordinate
                             (- (missile-y (first missiles)) MISSILE-SPEED)  ; Updated y-coordinate
                             (missile-fired-by (first missiles))) ; Keep the fired-by designation
               (move-missiles (rest missiles))))]))  ; Move the rest of the missiles

; move-invaders : List of Invaders -> List of Invaders
; Moves each invader diagonally and bounces them off the walls if necessary.
(define (move-invaders invaders)
  (cond
    [(empty? invaders) empty]
    [else
     (cons (update-invader (first invaders))
           (move-invaders (rest invaders)))]))
; Helper function to update a single invader
(define (update-invader inv)
  (make-invader
   (new-invader-x inv)
   (new-invader-y inv)
   (new-invader-dx inv)
   (new-invader-dy inv)))
; Compute new x-coordinate
(define (new-invader-x inv)
  (+ (invader-x inv) (invader-dx inv)))
; Compute new y-coordinate
(define (new-invader-y inv)
  (+ (invader-y inv) (invader-dy inv)))
; Compute new x-direction
(define (new-invader-dx inv)
  (if (or (< (new-invader-x inv) 0)
          (> (new-invader-x inv) SCREEN-WIDTH))
      (- (invader-dx inv))
      (invader-dx inv)))
; Compute new y-direction
(define (new-invader-dy inv)
  (if (or (< (new-invader-y inv) 0)
          (> (new-invader-y inv) SCREEN-HEIGHT))
      (- (invader-dy inv))
      (invader-dy inv)))






;;Game over function with helper
; tank-hit? : Invader Number -> Boolean
; tank-hit? : Invader Number -> Boolean
; Checks if an invader has hit the tank.
(define (tank-hit? invader tank-x)
  (and (>= (invader-y invader) (- SCREEN-HEIGHT 40)) ; Close to the bottom
       (<= (abs (- (invader-x invader) tank-x)) 20))) ; Within tank's width

; missile-hit-tank? : Missile Number -> Boolean
; Checks if a missile has hit the tank.
(define (missile-hit-tank? missile tank-x)
  (and (<= (missile-y missile) SCREEN-HEIGHT) ; Ensuring missile is in visible area
       (<= (abs (- (missile-x missile) tank-x)) 20))) ; Within tank's width
; invader-collides? : List of Invaders Number -> Boolean
; Returns true if any invader in the list has collided with the tank.
(define (invader-collides? invaders tank-x)
  (cond
    [(empty? invaders) #false] ; No invaders left to check
    [(tank-hit? (first invaders) tank-x) #true] ; An invader hit the tank
    [else (invader-collides? (rest invaders) tank-x)])) ; Check the rest of the invaders
; missile-collides? : List of Missiles Number -> Boolean
; Returns true if any enemy missile in the list has collided with the tank.
(define (missile-collides? missiles tank-x)
  (cond
    [(empty? missiles) #false] ; No missiles left to check
    [(and (string=? (missile-fired-by (first missiles)) "invader") ; Only check enemy missiles
          (missile-hit-tank? (first missiles) tank-x)) #true]
    [else (missile-collides? (rest missiles) tank-x)])) ; Check the rest of the missiles
;; Assuming invaders fire missiles
(define (invader-fire world invader)
  (make-world (world-tank world)
              (cons (make-missile (invader-x invader) (invader-y invader) "invader") ; Mark invader missiles
                    (world-missiles world))
              (world-invaders world)))


;; Updated game-over? function to only end if the tank is hit by invaders or enemy missiles
(define (game-over? world)
  (or (invader-collides? (world-invaders world) (world-tank world))
      (missile-collides? (world-missiles world) (world-tank world)))) ; Check only enemy missiles

;;HtDW Big Bang
(big-bang initial-world
  (on-tick update-world)
  (to-draw render-world)
  (on-key handle-key)
  (stop-when game-over?))

