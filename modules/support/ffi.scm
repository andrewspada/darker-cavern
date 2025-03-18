(define-module (support ffi)
  #:use-module (dom promise)
  #:use-module (goblins)
  #:use-module (hoot ffi)
  #:export (extern->promise
            lambda/external))

(define-syntax lambda/external
  (syntax-rules ()
    ((lambda/external rest ...)
     (procedure->external
      (lambda rest ...)))))

(define (extern->promise extern)
  (define-values (a-promise a-resolver)
    (spawn-promise-and-resolver))
  (then extern
        (lambda/external (result)
          (<-np-extern a-resolver 'fulfill result))
        (lambda/external (problem)
           (<-np-extern a-resolver 'break problem)))
  a-promise)

(define (with-unspecified-result proc)
  (lambda args
    (apply proc args)
    *unspecified*))

(define (with-promise-result proc)
  (lambda args
    (extern->promise (apply proc args))))
