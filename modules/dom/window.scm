(define-module (dom window)
  #:use-module (hoot ffi)
  #:use-module (support ffi)
  #:export (create-image-bitmap
            fetch
            request-animation-frame
            set-interval!))

;; Window
(define-foreign %create-image-bitmap
  "window" "createImageBitmap"
  (ref extern) -> (ref extern))
(define create-image-bitmap (with-promise-result %create-image-bitmap))

(define-foreign %fetch
  "window" "fetch"
  (ref string) -> (ref extern))
(define fetch (with-promise-result %fetch))

(define-foreign %request-animation-frame
  "window" "requestAnimationFrame"
  (ref extern) -> none)
(define request-animation-frame (with-unspecified-result %request-animation-frame))

(define-foreign %set-interval!
  "window" "setInterval"
  (ref extern) f64 -> none)
(define set-interval! (with-unspecified-result %set-interval!))
