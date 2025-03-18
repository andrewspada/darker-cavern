(define-module (dom image-bitmap)
  #:use-module (hoot ffi)
  #:export (image-bitmap-height
            image-bitmap-width))

;; ImageBitmap
(define-foreign image-bitmap-height
  "imageBitmap" "height"
  (ref extern) -> f64)

(define-foreign image-bitmap-width
  "imageBitmap" "width"
  (ref extern) -> f64)
