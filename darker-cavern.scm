(use-modules (dom audio)
             (dom canvas)
             (dom console)
             (dom document)
             (dom event)
             (dom image-bitmap)
             (dom response)
             (dom window)
             (goblins actor-lib cell)
             (goblins actor-lib joiners)
             (goblins actor-lib let-on)
             (goblins actor-lib methods)
             (goblins)
             (hoot records)
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

(define *canvas* (get-element-by-id "game"))
(define *context* (get-context *canvas* "2d"))
(define *audio-context* (make-audio-context))

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
                  (if (= 1 (remainder clock 50))
                      (list (make-sound-event 'meow))
                      '())))
           ((describe-scene)
            (list (make-sprite/prim
                   'snep
                   (let* ((theta (/ clock 100))
                          (scale (+ 1 (sin (/ clock 70))))
                          (s (* scale (sin theta)))
                          (c (* scale (cos theta))))
                     (make-transform c s (- s) c x y)))))))

(define (^player/intent bcom direction shooting?)
  (methods ((move new-direction)
            (bcom (^player/intent bcom new-direction shooting?)))
           ((shoot)
            (bcom (^player/intent bcom direction #t)))
           ((direction)
            direction)
           ((shooting?)
            shooting?)
           ((clear-shooting)
            (bcom (^player/intent bcom direction #f)))))

(define (^robot/intent bcom direction shooting?)
  (methods ((move new-direction)
            (bcom (^robot/intent bcom new-direction shooting?)))
           ((shoot)
            (bcom (^robot/intent bcom direction #t)))
           ((direction)
            direction)
           ((shooting?)
            shooting?)
           ((clear-shooting)
            (bcom (^robot/intent bcom direction #f)))))

(define (^spider/intent bcom direction)
  (methods ((move new-direction)
            (bcom (^spider/intent bcom new-direction)))
           (direction)
           direction))

(define (^blob/intent bcom direction)
  (methods ((move new-direction)
            (bcom (^blob/intent bcom new-direction)))
           (direction)
           direction))

(define* (^resource-store bcom #:optional (resource-list '()))
  (methods ((put name resource)
            (bcom (^resource-store bcom (acons name resource resource-list))))
           ((get name)
            (assoc-ref resource-list name))))



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
  (log (format #f "handle-events ~a" events))
  (for-each handle-event events))

(define (handle-event event)
  (log (format #f "handle-event ~a" event))
  (cond
   ((sound-event? event) (handle-sound-event event))
   (else (error "Unhandled event type" event))))

(define (handle-sound-event sound-event)
  (log (format #f "handle-sound-event ~a" sound-event))
  ($ *audio-player* 'play-sound (sound-event-name sound-event)))

(define (^audio-player bcom)
  (methods
   ((play-sound name)
    (let ((source (make-audio-buffer-source-node
                   *audio-context*
                   ($ *resource-store* 'get name)))
          (destination (audio-context-destination *audio-context*)))
      (connect-audio-node source destination)
      (start-audio-buffer source)))))

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

(define (load-resource name url ok-response->resource-vow)
  (let-on ((response (fetch url)))
    (unless (response-ok? response)
      (error "response not ok" name url))
    (let-on ((resource (ok-response->resource-vow response)))
      ($ *resource-store* 'put name resource))))

(define* (load-sprite name url #:optional origin)
  (define (ok-response->sprite-vow response)
    (let*-on ((blob (response->blob-vow response))
              (texture (create-image-bitmap blob)))
      (make-sprite texture
                   (or origin
                       (make-point (/ (image-bitmap-width texture) 2)
                                   (/ (image-bitmap-height texture) 2))))))
  (load-resource name url ok-response->sprite-vow))

(define (load-sound name url)
  (define (ok-response->sound-vow response)
    (let-on ((array-buffer (response->array-buffer-vow response)))
      (decode-audio-data *audio-context* array-buffer)))
  (load-resource name url ok-response->sound-vow))

(with-vat client-vat
  (define snep-vow (load-sprite 'snep "assets/snep.jpeg"))
  (define meow-vow (load-sound 'meow "assets/meow.ogg"))
  (define-values (click-vow click-resolver)
    (spawn-promise-and-resolver))
  (add-event-listener! *canvas*
                       "click"
                       (lambda/external (e)
                         (<-np-extern click-resolver
                                      'fulfill
                                      'clicked)))
  (log (format #f "snep-vow ~a" snep-vow))
  (log (format #f "meow-vow ~a" meow-vow))
  (on (all-of snep-vow meow-vow click-vow)
      (lambda _
        (setup-game-callbacks))))


;; Local Variables:
;; eval: (put 'with-vat 'scheme-indent-function 1)
;; eval: (put 'let-on 'scheme-indent-function 1)
;; eval: (put 'let*-on 'scheme-indent-function 1)
;; eval: (put 'lambda/external 'scheme-indent-function 1)
;; End:
