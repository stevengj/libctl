; libctl: flexible Guile-based control files for scientific software 
; Copyright (C) 1998, 1999, 2000, 2001, Steven G. Johnson
;
; This library is free software; you can redistribute it and/or
; modify it under the terms of the GNU Lesser General Public
; License as published by the Free Software Foundation; either
; version 2 of the License, or (at your option) any later version.
;
; This library is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
; Lesser General Public License for more details.
; 
; You should have received a copy of the GNU Lesser General Public
; License along with this library; if not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
; Boston, MA  02111-1307, USA.
;
; Steven G. Johnson can be contacted at stevenj@alum.mit.edu.

; ****************************************************************
; Replacements for MIT Scheme functions missing from Guile 1.2.

(define true #t)
(define false #f)

(define (list-transform-positive l pred)
  (if (null? l)
      l
      (if (pred (car l))
	  (cons (car l) (list-transform-positive (cdr l) pred))
	  (list-transform-positive (cdr l) pred))))

(define (list-transform-negative l pred)
  (if (null? l)
      l
      (if (not (pred (car l)))
	  (cons (car l) (list-transform-negative (cdr l) pred))
	  (list-transform-negative (cdr l) pred))))

(define (alist-copy al)
  (if (null? al) '()
      (cons (cons (caar al) (cdar al)) (alist-copy (cdr al)))))

(define (for-all? l pred)
  (if (null? l)
      true
      (if (pred (car l))
	  (for-all? (cdr l) pred)
	  false)))

(define (first list) (list-ref list 0))
(define (second list) (list-ref list 1))
(define (third list) (list-ref list 2))
(define (fourth list) (list-ref list 3))
(define (fifth list) (list-ref list 4))
(define (sixth list) (list-ref list 5))

(define (fold-right op init list)
  (if (null? list)
      init
      (op (car list) (fold-right op init (cdr list)))))

; ****************************************************************
; Miscellaneous utility functions.

(define (compose f g) (lambda args (f (apply g args))))

(define (car-or-x p) (if (pair? p) (car p) p))

; combine 2 alists.  returns a list containing all of the associations
; in a1 and any associations in a2 that are not in a1
(define (combine-alists a1 a2)
  (if (null? a2)
      a1
      (combine-alists
       (if (assoc (caar a2) a1) a1 (cons (car a2) a1))
       (cdr a2))))

(define (vector-for-all? v pred) (for-all? (vector->list v) pred))

(define (vector-fold-right op init v)
  (fold-right op init (vector->list v)))

(define (vector-map func . v)
  (list->vector (apply map (cons func (map vector->list v)))))

(define (indent indentby)
  (display (make-string indentby #\space)))

(define (display-many . items)
  (for-each (lambda (item) (display item)) items))

(define (make-initialized-list size init-func)
  (define (aux i)
    (if (>= i size) '()
	(cons (init-func i) (aux (+ i 1)))))
  (aux 0))

; ****************************************************************

; Some string utilities:

(define (string-find-next-char-in-list s l)
  (define (aux index s)
    (if (string-null? s)
	#f
	(if (member (string-ref s 0) l)
	    index
	    (aux (+ index 1) (substring s 1 (string-length s))))))
  (aux 0 s))

(define (string-find-next-char-not-in-list s l)
  (define (aux index s)
    (if (string-null? s)
	#f
	  (if (not (member (string-ref s 0) l))
	      index
	      (aux (+ index 1) (substring s 1 (string-length s))))))
  (aux 0 s))

(define (string->positive-integer s)
  (let ((non-blank (string-find-next-char-not-in-list
		    s '(#\space #\ht #\vt #\nl #\cr))))
    (let ((s2 (if (eq? non-blank #f)
		  s (substring s non-blank (string-length s)))))
      (let ((int-start (string-find-next-char-in-list
			s2 (string->list "0123456789"))))
	(if (eq? int-start 0)
	    (let ((int-end (string-find-next-char-not-in-list
			    (substring s2 1 (string-length s2))
			    (string->list "0123456789"))))
	      (if (eq? int-end #f)
		  (eval-string s2)
		  (if (string-find-next-char-not-in-list
		       (substring s2 (+ 1 int-end) (string-length s2))
		       '(#\space #\ht #\vt #\nl #\cr))
		      #f
		      (eval-string s2))))
	    #f)))))

; ****************************************************************

; timing functions

; Display the message followed by the time t in minutes and seconds,
; returning t in seconds.
(define (display-time message t)
  (let ((minutes (quotient t 60)) (seconds (remainder t 60)))
    (display message)
    (if (> minutes 1)
	(display-many minutes " minutes, ")
	(if (> minutes 0)
	    (display-many minutes " minute, ")))
    (display-many seconds " seconds.\n"))
  t)

; (begin-time message ...statements...) works just like (begin
; ...statements...) except that it also displays 'message' followed by
; the elapsed time to execute the statements.  Additionally, it returns
; the elapsed time in seconds, rather than the value of the last statement.
(defmacro-public begin-time (message . statements)
  `(begin
     (let ((begin-time-start-t (current-time)))
       ,@statements
       (display-time ,message (- (current-time) begin-time-start-t)))))

; ****************************************************************
