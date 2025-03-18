(define-module (dom promise)
  #:use-module (hoot ffi)
  #:export (then))

;; Promise
(define-foreign then
  "promise" "then"
  (ref extern) (ref extern) (ref extern) -> (ref extern))
