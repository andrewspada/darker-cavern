(define-record-type <input-state>
  (make-input-state up down left right space enter)
  input-state?
  (up input-state-up?)
  (down input-state-down?)
  (left input-state-left?)
  (right input-state-right?)
  (space input-state-space?)
  (enter input-state-enter?))

(define-record-type <rectangle/prim>
  (make-rectangle/prim x y w h color transform)
  rectangle/prim?
  (x rectangle/prim-x)
  (y rectangle/prim-y)
  (w rectangle/prim-w)
  (h rectangle/prim-h)
  (color rectangle/prim-color)
  (transform rectangle/prim-transform))

(define-record-type <sprite/prim>
  (make-sprite/prim name transform)
  sprite/prim?
  (name sprite/prim-name)
  (transform sprite/prim-transform))

(define-record-type <sprite>
  (make-sprite texture origin)
  sprite?
  (texture sprite-texture)
  (origin sprite-origin))

(define-record-type <point>
  (make-point x y)
  point?
  (x point-x)
  (y point-y))

(define-record-type <sound-event>
  (make-sound-event name)
  sound-event?
  (name sound-event-name))
