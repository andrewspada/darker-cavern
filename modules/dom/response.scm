(define-module (dom response)
  #:use-module (hoot ffi)
  #:use-module (support ffi)
  #:export (response->array-buffer-vow
            response->blob-vow
            response-ok?))

;; Response
(define-foreign %response->array-buffer-vow
  "response" "arrayBuffer"
  (ref extern) -> (ref extern))
(define response->array-buffer-vow (with-promise-result %response->array-buffer-vow))

(define-foreign %response->blob-vow
  "response" "blob"
  (ref extern) -> (ref extern))
(define response->blob-vow (with-promise-result %response->blob-vow))

(define-foreign %response-ok?
  "response" "ok"
  (ref extern) -> i32)
(define (response-ok? response)
  (eq? (%response-ok? response) 1))
