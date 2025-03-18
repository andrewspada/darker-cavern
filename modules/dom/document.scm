(define-module (dom document)
  #:use-module (hoot ffi)
  #:export (current-document
            get-element-by-id))

;; Document
(define-foreign current-document
  "document" "get"
  -> (ref extern))

(define-foreign get-element-by-id
  "document" "getElementById"
  (ref string) -> (ref null extern))
