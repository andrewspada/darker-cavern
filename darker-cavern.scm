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

;; Window
(define-foreign request-animation-frame'
  "window" "requestAnimationFrame"
  (ref extern) -> none)

(define-wrapper request-animation-frame request-animation-frame')

(define-wrapper log log')

(define *canvas* (get-element-by-id "game"))
(define *context* (get-context *canvas* "2d"))

(define tick-time (exact->inexact (/ 1 24)))
(define saturation-time 1)

(define client-vat (spawn-vat))
(define game-vat (spawn-vat))

(define (^player bcom x y)
  (methods ((move-up) (bcom (^player bcom x (- y 1))))
           ((move-down) (bcom (^player bcom x (+ y 1))))
           ((move-left) (bcom (^player bcom (- x 1) y)))
           ((move-right) (bcom (^player bcom (+ x 1) y)))
           ((get-x) x)
           ((get-y) y)))

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
             (else (error "No cell for key code" code))))))

(define *input-handler* (with-vat my-vat
                                  (spawn ^input-handler)))

(define* (^driver bcom game #:optional (unprocessed-time 0) (last-frame-time #f))
  (methods ((on-frame current-frame-time)
            (if last-frame-time
                (receive (ticks-due remaining-time)
                    (floor/ (min saturation-time
                                 (+ unprocessed-time
                                    current-frame-time
                                    (- last-frame-time)))
                            tick-time)
                  (repeat ticks-due (lambda ()
                                      ($ game 'tick)))
                  (
                )))


(add-event-listener! (current-document)
                     "keydown"
                     (procedure->external
                      (lambda (e)
                        (with-vat my-vat
                                  (let ((code (keyboard-event-code e)))
                                    ($ *input-handler* 'on-key-down code))))))

(add-event-listener! (current-document)
                     "keyup"
                     (procedure->external
                      (lambda (e)
                        (with-vat my-vat
                                  (let ((code (keyboard-event-code e)))
                                    ($ *input-handler* 'on-key-up code))))))

(request-animation-frame (procedure->external
                          (lambda (timestamp) #f)))

(with-vat my-vat
           ($ *painter* 'repaint))
