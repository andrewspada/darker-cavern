(define-module (dom console)
  #:use-module (hoot ffi)
  #:use-module (support ffi)
  #:export (log))


;; Console
(define-foreign %log
  "console" "log"
  (ref string) -> none)
(define log (with-unspecified-log %log))
