(use-modules (hoot ffi)
             (goblins)
             (goblins actor-lib methods)
             (goblins actor-lib cell)
             (ice-9 match)
             (ice-9 receive))

(define-syntax define-wrapper
  (syntax-rules ()
    ((define-wrapper wrapper wrapped)
     (define (wrapper . args)
       (apply wrapped args)
       #f))))

;; HTMLCanvasElement
(define-foreign get-context
  "canvas" "getContext"
  (ref extern) (ref string) -> (ref extern))

;; CanvasRenderingContext2D
(define-foreign fill-rect'
  "canvas" "fillRect"
  (ref extern) f64 f64 f64 f64 -> none)

(define-wrapper fill-rect fill-rect')

(define-foreign clear-rect'
  "canvas" "clearRect"
  (ref extern) f64 f64 f64 f64 -> none)

(define-wrapper clear-rect clear-rect')

(define-foreign fill-style'
  "canvas" "fillStyle"
  (ref extern) (ref string) -> none)

(define-wrapper fill-style fill-style')

(define-foreign set-transform!'
  "canvas" "setTransform"
  (ref extern) f64 f64 f64 f64 f64 f64 -> none)

(define (set-transform! transform)
  (set-transform!' (transform-a transform)
                   (transform-b transform)
                   (transform-c transform)
                   (transform-d transform)
                   (transform-e transform)
                   (transform-f transform))
  #f)

(define-foreign draw-image'
  "canvas" "drawImage"
  (ref extern) (ref extern) f64 f64 -> none)

(define-wrapper draw-image draw-image')

;; Document
(define-foreign get-element-by-id
  "document" "getElementById"
  (ref string) -> (ref null extern))

(define-foreign current-document
  "document" "get"
  -> (ref extern))

;; EventTarget
(define-foreign add-event-listener!'
  "event" "addEventListener"
  (ref extern) (ref string) (ref extern) -> none)

(define-wrapper add-event-listener! add-event-listener!')

;; KeyboardEvent
(define-foreign keyboard-event-code
  "event" "keyboardCode"
  (ref extern) -> (ref string))

;; Console
(define-foreign log'
  "console" "log"
  (ref string) -> none)

(define-wrapper log log')

;; Window
(define-foreign request-animation-frame'
  "window" "requestAnimationFrame"
  (ref extern) -> none)

(define-wrapper request-animation-frame request-animation-frame')

(define-foreign set-interval!'
  "window" "setInterval"
  (ref extern) f64 -> none)

(define-wrapper set-interval! set-interval!')

(define-foreign fetch
  "window" "fetch"
  (ref extern) (ref string) -> (ref extern))

(define-foreign create-image-bitmap
  "window" "createImageBitmap"
  (ref extern) -> (ref extern))

;; Promise
(define-foreign then
  "promise" "then"
  (ref extern) (ref extern) (ref extern) -> (ref extern))

;; Response
(define-foreign blob
  "response" "blob"
  (ref extern) -> (ref extern))

;; ImageBitmap
(define-foreign image-bitmap-height
  "imageBitmap" "height"
  (ref extern) -> f64)

(define-foreign image-bitmap-width
  "imageBitmap" "width"
  (ref extern) -> f64)



(define *canvas* (get-element-by-id "game"))
(define *context* (get-context *canvas* "2d"))

(define tick-time (exact->inexact (/ 1 24)))
(define saturation-time 1)

(define client-vat (spawn-vat #:name "client-vat"))
(define game-vat (spawn-vat #:name "game-vat"))

(define (^player bcom x y)
  (methods ((move-up) (bcom (^player bcom x (- y 1))))
           ((move-down) (bcom (^player bcom x (+ y 1))))
           ((move-left) (bcom (^player bcom (- x 1) y)))
           ((move-right) (bcom (^player bcom (+ x 1) y)))
           ((get-x) x)
           ((get-y) y)))

(define-record-type <input-state>
  (make-input-state up down left right space enter)
  input-state?
  (input-state-up up)
  (input-state-down down)
  (input-state-left left)
  (input-state-right right)
  (input-state-space space)
  (input-state-enter enter))

(define (^input-handler bcom)
  (define button-state:up (spawn ^cell #f))
  (define button-state:down (spawn ^cell #f))
  (define button-state:left (spawn ^cell #f))
  (define button-state:right (spawn ^cell #f))
  (define button-state:space (spawn ^cell #f))
  (define button-state:enter (spawn ^cell #f))
  (define (look-up-cell code)
    (match code
      ("ArrowUp" button-state:up)
      ("ArrowDown" button-state:down)
      ("ArrowLeft" button-state:left)
      ("ArrowRight" button-state:right)
      ("ArrowSpace" button-state:space)
      ("ArrowEnter" button-state:enter)
      (_ #f)))
  (methods ((on-key-down code)
            (cond
             ((look-up-cell code) => (lambda (c)
                                       ($ c #t)))))
           ((on-key-up code)
            (cond
             ((look-up-cell code) => (lambda (c)
                                       ($ c #f)))))
           ((query-key code)
            (cond
             ((look-up-cell code) => (lambda (c)
                                       ($ c)))
             (else (error "No cell for key code" code))))
           ((get-input-state)
            (make-input-state ($ button-state:up)
                              ($ button-state:down)
                              ($ button-state:left)
                              ($ button-state:right)
                              ($ button-state:space)
                              ($ button-state:enter)))))

(define *input-handler* (with-vat client-vat
                                  (spawn ^input-handler)))

(define (^game bcom)
  (methods ((tick input-state)
            '())
           ((decscribe-scene)
            '())))

(define (draw-scene primitives)
  (for-each draw-primitive primitives))

(define (handle-events events)
  (for-each handle-event events))

(define (draw-primitive primitive)
  (cond
   ((rectangle/prim? primitive) (draw-rectangle primitive))
   ((sprite/prim? primitive) (draw-sprite primitive))
   (else (error "Unhandled primitive type" primitive))))

(define (draw-rectangle rectangle/prim)
  #f)

(define (draw-sprite sprite/prim)
  (set-transform! (sprite/prim-transform sprite/prim))
  (

 (define (handle-event event)
  (cond
   ((sound-event? event) (handle-sound-event event))
   (else (error "Unhandled event type" event))))

(define (handle-sound-event sound-event)
  ($ *audio-player* 'play-sound (sound-event-name sound-event)))

(define-record-type <rectangle/prim>
  (make-rectangle/prim x y w h color)
  rectangle/prim?
  (rectangle/prim-x x)
  (rectangle/prim-y y)
  (rectangle/prim-w w)
  (rectangle/prim-h h)
  (rectangle/prim-color color))

(define-record-type <sprite/prim>
  (make-sprite/prim name transform)
  sprite/prim?
  (sprite/prim-name name)
  (sprite/prim-transform transform))

(define-record-type <sprite>
  (make-sprite texture origin)
  sprite?
  (sprite-texture texture)
  (sprite-origin origin))

(define-record-type <point>
  (make-point x y)
  point?
  (point-x x)
  (point-y y))

(define-record-type <sound-event>
  (make-sound-event name)
  sound-event?
  (sound-event-name name))

(define-record-type <transform>
  (make-transform a b c d e f)
  transform?
  (transform-a a)
  (transform-b b)
  (transform-c c)
  (transform-d d)
  (transform-e e)
  (transform-f f))

(define (^audio-player bcom)
  (methods ((play-sound name)
            #f)))

(define *audio-player*
  (with-vat client-vat
            (spawn ^audio-player)))

(define *game*
  (with-vat game-vat
            (spawn ^game)))


(set-interval! (procedure->external
                (lambda ()
                  (with-vat client-vat
                            (on
                             (<- *game*
                                 'tick
                                 ($ *input-handler* 'get-input-state))
                             handle-events)))))


(add-event-listener! (current-document)
                     "keydown"
                     (procedure->external
                      (lambda (e)
                        (<-np-extern *input-handler* 'on-key-down (keyboard-event-code e)))))

(add-event-listener! (current-document)
                     "keyup"
                     (procedure->external
                      (lambda (e)
                        (<-np-extern *input-handler* 'on-key-up (keyboard-event-code e)))))

(request-animation-frame (procedure->external
                          (lambda (timestamp)
                            (with-vat client-vat
                                      (on
                                       (<- *game*
                                           'describe-scene)
                                       draw-scene)))))

(with-vat my-vat
           ($ *painter* 'repaint))
