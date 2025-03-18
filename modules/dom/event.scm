(define-module (dom event)
  #:use-module (hoot ffi)
  #:use-module (support ffi)
  #:export (add-event-listener!
            keyboard-event-code))


;; EventTarget
(define-foreign %add-event-listener!
  "event" "addEventListener"
  (ref extern) (ref string) (ref extern) -> none)
(define add-event-listener! (with-unspecified-result %add-event-listener!))

;; KeyboardEvent
(define-foreign keyboard-event-code
  "event" "keyboardCode"
  (ref extern) -> (ref string))
