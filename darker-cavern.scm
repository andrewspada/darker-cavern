(use-modules (hoot ffi)
             (goblins)
             (goblins actor-lib methods))

;; HTMLCanvasElement
(define-foreign get-context
  "canvas" "getContext"
  (ref extern) (ref string) -> (ref extern))

;; CanvasRenderingContext2D
(define-foreign fill-rect
  "canvas" "fillRect"
  (ref extern) f64 f64 f64 f64 -> none)

(define-foreign clear-rect
  "canvas" "clearRect"
  (ref extern) f64 f64 f64 f64 -> none)

;; Document
(define-foreign get-element-by-id
  "document" "getElementById"
  (ref string) -> (ref null extern))

(define-foreign current-document
  "document" "get"
  -> (ref extern))

;; EventTarget
(define-foreign add-event-listener!
  "event" "addEventListener"
  (ref extern) (ref string) (ref extern) -> none)

;; KeyboardEvent
(define-foreign keyboard-event-code
  "event" "keyboardCode"
  (ref extern) -> (ref string))

(define *canvas* (get-element-by-id "game"))
(define *context* (get-context *canvas* "2d"))

(define my-vat (spawn-vat))

(define (^player bcom x y)
  (methods ((move-up) (bcom (^player bcom x (- y 1))))
           ((move-down) (bcom (^player bcom x (+ y 1))))
           ((move-left) (bcom (^player bcom (- x 1) y)))
           ((move-right) (bcom (^player bcom (+ x 1) y)))
           ((get-x) x)
           ((get-y) y)))

(define *player* (with-vat my-vat
                             (spawn ^player 0 0)))

(define (^painter bcom player context)
  (methods ((repaint) (let ((x ($ player 'get-x))
                            (y ($ player 'get-y)))
                        (clear-rect context 0 0 500 500)
                        (fill-rect context x y 150 100)))))

(define *painter* (with-vat my-vat
                    (spawn ^painter *player* *context*)))
  

(add-event-listener! (current-document)
                     "keydown"
                     (procedure->external
                      (lambda (e)
                        (with-vat my-vat
                                  (let ((code (keyboard-event-code e)))
                                    (cond
                                     ((string=? code "ArrowDown") ($ *player* 'move-down))
                                     ((string=? code "ArrowUp") ($ *player* 'move-up))
                                     ((string=? code "ArrowLeft") ($ *player* 'move-left))
                                     ((string=? code "ArrowRight") ($ *player* 'move-right))))
                                  ($ *painter* 'repaint)))))

(with-vat my-vat
          ($ *painter* 'repaint))
