(define game-vat (spawn-vat #:name "game-vat"))

(define (^player/intent bcom direction shooting?)
  (methods ((move new-direction)
            (bcom (^player/intent bcom new-direction shooting?)))
           ((shoot)
            (bcom (^player/intent bcom direction #t)))
           ((direction)
            direction)
           ((shooting?)
            shooting?)
           ((clear-shooting)
            (bcom (^player/intent bcom direction #f)))))

(define (^robot/intent bcom direction shooting?)
  (methods ((move new-direction)
            (bcom (^robot/intent bcom new-direction shooting?)))
           ((shoot)
            (bcom (^robot/intent bcom direction #t)))
           ((direction)
            direction)
           ((shooting?)
            shooting?)
           ((clear-shooting)
            (bcom (^robot/intent bcom direction #f)))))

(define (^spider/intent bcom direction)
  (methods ((move new-direction)
            (bcom (^spider/intent bcom new-direction)))
           (direction)
           direction))

(define (^blob/intent bcom direction)
  (methods ((move new-direction)
            (bcom (^blob/intent bcom new-direction)))
           (direction)
           direction))

;; ^stage
;; ^game-obj:player
;; ^game-obj:robot
;; ^game-obj:spider
;; ^game-obj:blob
;; ^stage-manager
;; ^backstage
;; ^game-obj:player/puppeteer
;; ^game-obj:robot/puppeteer
;; ^game-obj:spider/puppeteer
;; ^game-obj:blob/puppeteer
;; ^game-obj:collision-detector
;; ^game-obj:timer
;; ^game-obj:scoreboard
;; ^game-obj:ammo-counter
;; ^persp:player->stage
;; ^persp:player->robot
;; ^persp:player->spider
;; ^persp:player->blob
;; ^persp:player->scoreboard
;; ^persp:player->ammo-counter
;; ^persp:enemy->stage
;; ^persp:enemy->player
;; ^persp:enemy->robot
;; ^persp:enemy->spider
;; ^persp:enemy->blob
;; ^director

(define (^persp:player->stage bcom player-visible-stage-entrance-pubsub player-visible-stage)
  (lambda (subscriber)
    ($ player-visible-stage-entrance-pubsub 'subscribe subscriber)
    ($ player-visible-stage 'list)))

(define (make-persp:player->stage stage-entance-pubsub stage)
  (let ((player-visible-stage-entrance-pubsub
         (make-player-visible-stage-entrance-pubsub stage-entrance-pubsub))
        (player-visible-stage (spawn ^player-visible-stage stage))
        (spawn ^persp:player->stage player-visible-stage-entrance-pubsub player-visible-stage))))

(define (make-player-visible-stage-entrance-pubsub stage-entrance-pubsub)
  (define player-visible-stage-entrance-pubsub (spawn ^pubsub))
  ($ stage-entrance-pubsub
     'subscribe
     (spawn
      (lambda (bcom)
        (methods
         ((add game-obj)
          (when (game-obj-player-visible? game-obj)
            ($ player-visible-stage-entrance-pubsub 'publish (error "TODO")))))))
  player-visible-stage-entrance-pubsub)

(define (^stage bcom stage-entrance-pubsub #:optional (game-objs '()))
  (methods ((add game-obj)
            ($ stage-entrance-pubsub 'publish 'add game-obj)
            (bcom (^stage bcom stage-entrance-pubsub (cons game-obj game-objs))))
           ((list) game-objs)
           ((do-phase phase)
            (for-each (lambda (obj) ($ obj 'do-phase phase))
                      game-objs))))

(define (^player-visible-stage bcom stage)
  (methods ((list)
            (let* ((all-objs ($ stage 'list))
                   (player-visible-objs (filter game-obj-player-visible? all-objs)))
              (map from-player-persp player-visible-objs)))))

(define (from-player-persp game-obj)
  (cond
   ((game-obj:robot? game-obj) (make-persp:player->robot ($ game-obj 'get-update-pubsub)  game-obj))
   (else (error "TODO"))))

(define (^persp:player->robot bcom player-visible-robot-update-pubsub player-visible-robot)
  (lambda (subscriber)
    ($ player-visible-robot-update-pubsub 'subscrube subscriber)
    ($ player-visible-robot 'describe)))

(define (make-persp:player->robot robot-update-pubsub robot)
  (let ((player-visible-robot-update-pubsub (error "TODO"))
        (player-visible-robot (spawn ^player-visible-robot robot))
    (spawn ^persp:player->robot player-visible-robot-update-pubsub player-visible-robot)))

(define (^player-visible-robot bcom robot)
  (methods ((describe)
            `(robot ,($ robot 'pose) ,($ robot 'state)))))
