(use-modules (hoot ffi)
             (hoot records)
             (goblins)
             (goblins actor-lib methods)
             (goblins actor-lib cell)
             (goblins actor-lib let-on)
             (ice-9 match))

(define-record-type <input-state>
  (make-input-state up down left right space enter)
  input-state?
  (up input-state-up?)
  (down input-state-down?)
  (left input-state-left?)
  (right input-state-right?)
  (space input-state-space?)
  (enter input-state-enter?))

(define-record-type <rectangle/prim>
  (make-rectangle/prim x y w h color transform)
  rectangle/prim?
  (x rectangle/prim-x)
  (y rectangle/prim-y)
  (w rectangle/prim-w)
  (h rectangle/prim-h)
  (color rectangle/prim-color)
  (transform rectangle/prim-transform))

(define-record-type <sprite/prim>
  (make-sprite/prim name transform)
  sprite/prim?
  (name sprite/prim-name)
  (transform sprite/prim-transform))

(define-record-type <sprite>
  (make-sprite texture origin)
  sprite?
  (texture sprite-texture)
  (origin sprite-origin))

(define-record-type <point>
  (make-point x y)
  point?
  (x point-x)
  (y point-y))

(define-record-type <sound-event>
  (make-sound-event name)
  sound-event?
  (name sound-event-name))

(define-record-type <transform>
  (make-transform a b c d e f)
  transform?
  (a transform-a)
  (b transform-b)
  (c transform-c)
  (d transform-d)
  (e transform-e)
  (f transform-f))

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

(define-foreign set-fill-style!'
  "canvas" "setFillStyle"
  (ref extern) (ref string) -> none)

(define-wrapper set-fill-style! set-fill-style!')

(define-foreign set-transform!'
  "canvas" "setTransform"
  (ref extern) f64 f64 f64 f64 f64 f64 -> none)

(define (set-transform! context transform)
  (set-transform!' context
                   (transform-a transform)
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

(define-foreign fill-text'
  "canvas" "fillText"
  (ref extern) (ref string) f64 f64 -> none)

(define-wrapper fill-text fill-text')


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

(define-foreign %fetch
  "window" "fetch"
  (ref string) -> (ref extern))

(define (extern->promise extern)
  (define-values (a-promise a-resolver)
    (spawn-promise-and-resolver))
  (then extern
        (lambda/external (result)
          (<-np-extern a-resolver 'fulfill result))
        (lambda/external (problem)
           (<-np-extern a-resolver 'break problem)))
  a-promise)

(define-syntax lambda/external
  (syntax-rules ()
    ((lambda/external rest ...)
     (procedure->external
      (lambda rest ...)))))

(define (fetch resource)
  (extern->promise (%fetch resource)))

(define-foreign %create-image-bitmap
  "window" "createImageBitmap"
  (ref extern) -> (ref extern))

(define (create-image-bitmap image)
  (extern->promise (%create-image-bitmap image)))

;; Promise
(define-foreign then
  "promise" "then"
  (ref extern) (ref extern) (ref extern) -> (ref extern))

;; Response
(define-foreign %response->blob-promise
  "response" "blob"
  (ref extern) -> (ref extern))

(define (response->blob-promise response)
  (extern->promise (%response->blob-promise response)))

(define-foreign %response-ok?
  "response" "ok"
  (ref extern) -> i32)

(define (response-ok? response)
  (eq? (%response-ok? response) 1))

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

(define identity-transform
  (make-transform 1 0 0 1 0 0))

(define client-vat (spawn-vat #:name "client-vat"))
(define game-vat (spawn-vat #:name "game-vat"))

(define (^player bcom x y)
  (methods ((move-up) (bcom (^player bcom x (- y 1))))
           ((move-down) (bcom (^player bcom x (+ y 1))))
           ((move-left) (bcom (^player bcom (- x 1) y)))
           ((move-right) (bcom (^player bcom (+ x 1) y)))
           ((get-x) x)
           ((get-y) y)))

(define (clear)
  (set-transform! *context* identity-transform)
  (clear-rect *context* 0 0 500 500))

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

(define-actor (^game bcom #:optional (clock 0) (x 100) (y 100))
  (methods ((tick input-state)
            (bcom (^game bcom
                         (+ clock 1)
                         (+ x
                            (if (input-state-left? input-state) -1 0)
                            (if (input-state-right? input-state) 1 0))
                         (+ y
                            (if (input-state-up? input-state) -1 0)
                            (if (input-state-down? input-state) 1 0)))
                  '()))
           ((describe-scene)
            (list (make-sprite/prim
                   'snep
                   (let* ((theta (/ clock 100))
                          (scale (+ 1 (sin (/ clock 70))))
                          (s (* scale (sin theta)))
                          (c (* scale (cos theta))))
                     (make-transform c s (- s) c x y)))))))


(define* (^resource-store bcom #:optional (resource-list '()))
  (methods ((put name resource)
            (bcom (^resource-store bcom (acons name resource resource-list))))
           ((get name)
            (assq-ref resource-list name))))

(define *resource-store* (with-vat client-vat
                                   (spawn ^resource-store)))

(define (draw-scene primitives)
  (clear)
  (for-each draw-primitive primitives))

(define (draw-primitive primitive)
  (cond
   ((rectangle/prim? primitive) (draw-rectangle/prim primitive))
   ((sprite/prim? primitive) (draw-sprite/prim primitive))
   (else (error "Unhandled primitive type" primitive))))

(define (draw-rectangle/prim rectangle/prim)
  (set-transform! *context* (rectangle/prim-transform rectangle/prim))
  (set-fill-style! *context* (rectangle/prim-color rectangle/prim))
  (fill-rect *context*
             (rectangle/prim-x rectangle/prim)
             (rectangle/prim-y rectangle/prim)
             (rectangle/prim-w rectangle/prim)
             (rectangle/prim-h rectangle/prim)))

(define (draw-sprite/prim sprite/prim)
  (set-transform! *context* (sprite/prim-transform sprite/prim))
  (cond
   ((lookup-sprite (sprite/prim-name sprite/prim)) => draw-sprite)
   (else (draw-missing-sprite (sprite/prim-name sprite/prim)))))

(define (draw-sprite sprite)
  (draw-image *context*
              (sprite-texture sprite)
              (- (point-x (sprite-origin sprite)))
              (- (point-y (sprite-origin sprite)))))

(define (draw-missing-sprite name)
  (set-fill-style! *context* "red")
  (fill-text *context*
             (symbol->string name)
             0
             10)
  (fill-rect *context*
             -1 -1 2 2))

(define (lookup-sprite name)
  ($ *resource-store*
     'get
     name))

(define (handle-events events)
  (for-each handle-event events))

 (define (handle-event event)
  (cond
   ((sound-event? event) (handle-sound-event event))
   (else (error "Unhandled event type" event))))

(define (handle-sound-event sound-event)
  ($ *audio-player* 'play-sound (sound-event-name sound-event)))

(define (^audio-player bcom)
  (methods ((play-sound name)
            #f)))

(define *audio-player*
  (with-vat client-vat
            (spawn ^audio-player)))

(define *game*
  (with-vat game-vat
            (spawn ^game)))


(define (setup-game-event-handler)
  (set-interval! (procedure->external
                  (lambda ()
                    (with-vat client-vat
                              (on
                               (<- *game*
                                   'tick
                                   ($ *input-handler* 'get-input-state))
                               handle-events))))
                 10))


(define (setup-keydown-callback)
  (add-event-listener! (current-document)
                       "keydown"
                       (procedure->external
                        (lambda (e)
                          (<-np-extern *input-handler* 'on-key-down (keyboard-event-code e))))))

(define (setup-keyup-callback)
  (add-event-listener! (current-document)
                       "keyup"
                       (procedure->external
                        (lambda (e)
                          (<-np-extern *input-handler* 'on-key-up (keyboard-event-code e))))))

(define (animation-frame-callback timestamp)
  (setup-animation-frame-callback)
  (with-vat client-vat
            (on
             (<- *game*
                 'describe-scene)
             draw-scene)))

(define (setup-animation-frame-callback)
  (request-animation-frame (procedure->external animation-frame-callback)))

(define (setup-game-callbacks)
  (setup-game-event-handler)
  (setup-keydown-callback)
  (setup-keyup-callback)
  (setup-animation-frame-callback))

(with-vat client-vat
  (let-on ((response (fetch "assets/snep.jpeg")))
    (unless (response-ok? response)
      (error "response not ok"))
    (let*-on ((blob (response->blob-promise response))
              (texture (create-image-bitmap blob)))
      ($ *resource-store* 'put 'snep
         (make-sprite texture
                      (make-point (/ (image-bitmap-width texture) 2)
                                  (/ (image-bitmap-height texture) 2))))
      (setup-game-callbacks))))
