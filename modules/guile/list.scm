;;; List compatibility procedures/macros for Guile

;;; Copyright © 2024 Juliana Sims <juli@incana.org>
;;;
;;; Licensed under the Apache License, Version 2.0 (the "License");
;;; you may not use this file except in compliance with the License.
;;; You may obtain a copy of the License at
;;;
;;;    http://www.apache.org/licenses/LICENSE-2.0
;;;
;;; Unless required by applicable law or agreed to in writing, software
;;; distributed under the License is distributed on an "AS IS" BASIS,
;;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;;; See the License for the specific language governing permissions and
;;; limitations under the License.

;;; Commentary:
;;;
;;; These match APIs exposed in Guile's environment but not yet available in
;;; Hoot.

;;; Code:

(define-module (guile list)
  #:export (delete delq delq!))

(define (fold proc acc lst)
  (if (null? lst)
      acc
      (fold proc
            (proc (car lst) acc)
            (cdr lst))))

(define (fold-right proc acc lst)
  (fold proc acc (reverse lst)))

(define (delete item lst . eq-pair)
  (define eq (if (pair? eq-pair) (car eq-pair) equal?))
  (fold-right (lambda (i acc)
                (if (eq i item)
                    acc
                    (cons i acc)))
              '() lst))

(define (delq item lst)
  (delete item lst eq?))

;; This matches the semantics of Guile's delq!, but using set-car! means we
;; could actually improve delq! by ensuring eq? between an original list
;; starting with ITEM and a delq! removing ITEM from that list. Guile's delq!
;; does not provide this functionality because it does not destructively
;; remove the list's car
(define (delq! item lst)
  (let ((delqd-lst (delq item lst)))
    (if (eq? (car lst) item)
        (and (set-cdr! lst delqd-lst)
             delqd-lst)
        (and (set-cdr! lst (cdr delqd-lst))
             (set-car! lst (car delqd-lst))
             lst))))
