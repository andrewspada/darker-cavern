(define-module (game client)
  #:use-module (dom audio)
  #:use-module (dom canvas)
  #:use-module (dom console)
  #:use-module (dom document)
  #:use-module (dom event)
  #:use-module (dom image-bitmap)
  #:use-module (dom response)
  #:use-module (dom window)
  #:use-module (game types)
  #:export (start-client))

(define *canvas* (get-element-by-id "game"))
(define *context* (get-context *canvas* "2d"))
(define *audio-context* (make-audio-context))

(define (clear)
  (set-transform! *context* identity-transform)
  (clear-rect *context* 0 0 500 500))

(define client-vat (spawn-vat #:name "client-vat"))

(define identity-transform
  (make-transform 1 0 0 1 0 0))

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

(define* (^resource-store bcom #:optional (resource-list '()))
  (methods ((put name resource)
            (bcom (^resource-store bcom (acons name resource resource-list))))
           ((get name)
            (assoc-ref resource-list name))))

(define *resource-store* (with-vat client-vat
                           (spawn ^resource-store)))

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

(define (start-client)
  (with-vat client-vat
    (define-values (click-vow click-resolver)
      (spawn-promise-and-resolver))
    (add-event-listener! *canvas*
                         "click"
                         (lambda/external (e)
                           (<-np-extern click-resolver
                                        'fulfill
                                        'clicked)))
    (on (all-of (load-sprite 'snep "assets/snep.jpeg")
                (load-sound 'meow "assets/meow.ogg")
                click-vow)
        (lambda _
          (setup-game-callbacks)))))
