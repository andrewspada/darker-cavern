;;; Copyright (C) 2010, 2011, 2013, 2024 Free Software Foundation, Inc.
;;;
;;; This library is free software; you can redistribute it and/or
;;; modify it under the terms of the GNU Lesser General Public
;;; License as published by the Free Software Foundation; either
;;; version 3 of the License, or (at your option) any later version.
;;;
;;; This library is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Lesser General Public License for more details.
;;;
;;; You should have received a copy of the GNU Lesser General Public
;;; License along with this library; if not, write to the Free Software
;;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

;;; Commentary:
;;;
;;; This is a convenience module for porting Goblins to Hoot while Guile support
;;; is incomplete. It simply re-exports some extant Hoot prompt functionality
;;; and adds call-with-escape-continuation and call/ec.
;;;
;;; Code:

(define-module (ice-9 control)
  #:export (make-prompt-tag
            default-prompt-tag
            call-with-prompt
            abort-to-prompt

            %
            default-prompt-handler

            call-with-escape-continuation
            call/ec))

(define (call-with-escape-continuation proc)
  "Call PROC with an escape continuation."
  (let ((tag (list 'call/ec)))
    (call-with-prompt tag
      (lambda ()
        (proc (lambda args
                (apply abort-to-prompt tag args))))
      (lambda (_ . args)
        (apply values args)))))

(define call/ec call-with-escape-continuation)
