(define-module (dom canvas)
  #:use-module (hoot ffi)
  #:use-module (support ffi)
  #:export (clear-rect
            draw-image
            fill-rect
            fill-text
            get-context
            set-fill-style!
            set-transform!))

(define-record-type <transform>
  (make-transform a b c d e f)
  transform?
  (a transform-a)
  (b transform-b)
  (c transform-c)
  (d transform-d)
  (e transform-e)
  (f transform-f))

;; CanvasRenderingContext2D
(define-foreign %clear-rect
  "canvas" "clearRect"
  (ref extern) f64 f64 f64 f64 -> none)
(define clear-rect (with-unspecified-result %clear-rect))

(define-foreign %draw-image
  "canvas" "drawImage"
  (ref extern) (ref extern) f64 f64 -> none)
(define draw-image (with-unspecified-result %draw-image))

(define-foreign %fill-rect
  "canvas" "fillRect"
  (ref extern) f64 f64 f64 f64 -> none)
(define fill-rect (with-unspecified-result %fill-rect))

(define-foreign %fill-text
  "canvas" "fillText"
  (ref extern) (ref string) f64 f64 -> none)
(define fill-text (with-unspecified-result %fill-text))

(define-foreign %set-fill-style!
  "canvas" "setFillStyle"
  (ref extern) (ref string) -> none)
(define set-fill-style (with-unspecified-result %set-fill-style!))

(define-foreign %set-transform!
  "canvas" "setTransform"
  (ref extern) f64 f64 f64 f64 f64 f64 -> none)
(define (set-transform! context transform)
  (%set-transform! context
                   (transform-a transform)
                   (transform-b transform)
                   (transform-c transform)
                   (transform-d transform)
                   (transform-e transform)
                   (transform-f transform))
  *unspecified*)

;; HTMLCanvasElement
(define-foreign get-context
  "canvas" "getContext"
  (ref extern) (ref string) -> (ref extern))
