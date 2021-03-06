;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname |6-space invader game 2|) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
; REQUIREMENTS
;-------------
(require 2htdp/image)
(require 2htdp/universe)
;-------------
; CONSTANTS
;-------------
(define HEIGHT 500)
(define WIDTH 400)
(define UFO-DELTA 3)
(define MIS-DELTA (* 4 UFO-DELTA))
(define TANK-DELTA 8)

(define UFO (overlay (circle 10 "solid" "green")
                     (rectangle 50 8 "solid" "green")))
(define MISSILE (triangle 10 "solid" "red"))
(define TANK (rectangle 40 30 "solid" "blue"))
(define BG (empty-scene WIDTH HEIGHT))
;-------------
; DATA DEFINITION
;-------------
(define-struct sigs [ufo tank missile])

; A UFO is a Posn
; interpretation (make-posn x y) is the UFO's location
; (using the top-down, left-to-right convention)

(define-struct tank [loc vel])
; A Tank is a structure:
;     (make-tank Number Number)
; interpretation (make-tank x dx) specifies the position:
; (x, HEIGHT) and the tank's speed: dx pixels/tick

; A Missle is one of:
;    - #false
;    - Posn
; interpretation #false means the missile hasn't been fired;
; (make-pson x y) is the missile's place after it's fired

; A SIGS is:
; - (make-sigs UFO Tank Missile)
; interpretation represents the complete state of a
; space invader game
;-------------------------
; Auxiliary Functions
;-------------------------
; UFO Image -> Image
; adds u to the given image im
(define (ufo-render u im)
  (place-image UFO (posn-x u) (posn-y u) im))

; Tank Image -> Image
; adds t to the given image im
(define (tank-render t im)
  (place-image TANK (tank-loc t) HEIGHT im))

; Missle Image -> Image
; adds m to the given image im
(define (mis-render m im)
  (cond
    [(boolean? m) im]
    [(posn? m)
     (place-image MISSILE (posn-x m) (posn-y m) im)]))

; Number -> Number
; make sure that the x-coordinate of objectives are in the right range [0, WIDTH]
(define (get-x n)
  (cond
    [(< n 0) 0]
    [(> n WIDTH) WIDTH]
    [else n]))

; Number -> Number
; get a random number (negative + positive)
(define (random-range n)
  (* (if (odd? (random n))
         -1
         1)
     (random n)))

; UFO -> UFO
; ufo falls at a constant speed and jumps a bit to the sides
(define (ufo-move u)
  (make-posn (get-x (+ (random-range 10) (posn-x u)))
             (if (> (+ (posn-y u) UFO-DELTA) HEIGHT)
                 HEIGHT
                 (+ (posn-y u) UFO-DELTA))))

; Tank -> Tank
; and tank moves at a constant speed horizontally
; change direction when the tank touches the boundary
(define (tank-move t)
  (make-tank (get-x (+ (tank-loc t) (tank-vel t)))
             (if (or (<= (+ (tank-loc t) (tank-vel t)) 0)
                     (>= (+ (tank-loc t) (tank-vel t)) WIDTH))
                 (* -1 (tank-vel t))
                 (tank-vel t))))

; Missile -> Missile
; missile moves (if any) vertically at a constant speed
(define (mis-move m)
  (cond [(boolean? m) m]
        [(posn? m)
         (make-posn (posn-x m)
             (- (posn-y m) MIS-DELTA))]))

; SIGS String -> SIGS
; change the direction of tank
(define (change-dir s str)
  (make-sigs (sigs-ufo s)
             (make-tank (tank-loc (sigs-tank s))
                        (* TANK-DELTA
                           (if (string=? str "left")
                               -1
                               1)))
             (sigs-missile s)))

;-------------------------
; Main Functions
;-------------------------
; SIGS -> Image
; adds Tank, UFO, and possibly Missile to
; the BG scene
(define (si-render s)
  (mis-render (sigs-missile s)
                  (tank-render (sigs-tank s)
                               (ufo-render (sigs-ufo s) BG))))

; SIGS -> Boolean
; if ufo lands or the missle hits the ufo, stop the game
(define (si-game-over? s)
  (or (= HEIGHT (posn-y (sigs-ufo s)))
      (if (boolean? (sigs-missile s))
          #false
          (and (< (abs (- (posn-y (sigs-ufo s)) (posn-y (sigs-missile s)))) (/ (image-height UFO) 2))
               (< (abs (- (posn-x (sigs-ufo s)) [posn-x [sigs-missile s]])) (/ (image-width UFO) 2))))))

; SIGS -> Image
; renders the "game over" image
(define (over-render s)
  (overlay (text "GAME OVER" 30 "black") (si-render s)))

; SIGS -> SIGS
; moves the objects for every clock tick
(define (si-move s)
  (make-sigs (ufo-move (sigs-ufo s))
             (tank-move (sigs-tank s))
             (if (and (posn? (sigs-missile s))
                      (<= (posn-y (sigs-missile s)) (posn-y (sigs-ufo s))))
                 #false
                 (mis-move (sigs-missile s)))))


; SIGS KeyEvent -> SIGS
; launch the missile (if not yet) when "space" pressed
; change the directiof of tank to left when "left" pressed
; change the direction of tank to right when "right" pressed
(define (si-control s ke)
  (cond
    [(or (key=? ke "left") (key=? ke "right"))
     (change-dir s ke)]
    [(and (key=? ke " ") (boolean? (sigs-missile s)))
     (make-sigs (sigs-ufo s)
                (sigs-tank s)
                (make-posn (tank-loc (sigs-tank s)) HEIGHT))]
    [else s]))

     
;-------------------------
; Booter
;-------------------------


; SIGS -> SIGS
(define (main s)
  (big-bang s
            [on-tick si-move]
            [on-key si-control]
            [to-draw si-render]
            [stop-when si-game-over? over-render]))
;-------------------------