#lang racket
;; This file contains a number of useful tools for testing racket adapton implementation.
;; many of these tools are specific to mergesort.

(require rackunit
         "merge-sort.rkt"
         "memo-table-modification-tools.rkt"
         "data-structures.rkt"
         "adapton.rkt")

(provide (all-defined-out))

;; ================================= Printing =================================

;; get-list-from-mergesort 
;; takes a FORCED node and computes the rest of the list before printing it. 

;; tests for get-list-from-mergesort
(module+ test
  (check-equal? (get-list-from-mergesort (force (merge-sort (build-input 10))))
                '(1 2 3 4 5 6 7 8 9 10)))

(define (get-list-from-mergesort a)
  (map force (get-unforced-list-from-mergesort a)))
;; ================================================

;; get-unforced-list-from-mergesort 
;; takes a FORCED node and computes the rest of the list without forcing
;; individual elements, returning a list of cells.

;; tests for get-list-from-mergesort
(module+ test
  (check-equal? (andmap cell? (get-unforced-list-from-mergesort 
                             (force (merge-sort (build-input 10))))) #t)
  (check-equal? (map force (get-unforced-list-from-mergesort
                             (force (merge-sort (build-input 10)))))
                '(1 2 3 4 5 6 7 8 9 10)))

(define (get-unforced-list-from-mergesort a)
  (cond
    [(empty? a) empty]
    [(empty? (cdr a)) (cons (car a) empty)]
    [else (cons (car a)
                (get-unforced-list-from-mergesort (force (cdr a))))]))

;; ================================================

;; print-list-from-delayed-list
;; takes a list formatted for input (like one created by build-input)
;; and returns it in a legible format.

;; tests for print-list-from-delayed-list
(module+ test
  ;; input with make-cell and cons
  (define teeny-input (make-cell 
                          (cons (cons (make-cell 3) empty)
                                (make-cell 
                                 (cons (cons (make-cell 6) empty)
                                       empty)))))
  ;; is the same as input with m-cons
  (define tiny-input (m-cons 3 (m-cons 2 (m-cons 1 empty))))
  ;; is the same as using build-list
  (define small-input (build-list 10))
  
  (check-equal? (print-list-from-delayed-list teeny-input)
                '((3) (6)))
  (check-equal? (print-list-from-delayed-list tiny-input)
                '((3) (2) (1)))
  (check-equal? (print-list-from-delayed-list small-input)
                '((10) (9) (8) (7) (6) (5) (4) (3) (2) (1))))

(define (print-list-from-delayed-list l)
  (cond
    [(empty? l) empty]
    [else (cons (list (force (car (car (force l)))))
                (print-list-from-delayed-list (cdr (force l))))]))

;; ========================= Formatted Input Construction ====================

;; m-cons builds a formatted list input like cons would.
;; see above for tests.
(define (m-cons l r)
  (make-cell (cons (cons (make-cell l) empty)
                   r)))

;; ==================================================

;; build-input builds a formatted list input from n to 1.
;; see above for tests.

(module+ test
  (check-equal? (print-list-from-delayed-list 
                 (build-input 3))
                (print-list-from-delayed-list 
                 (m-cons 3 (m-cons 2 (m-cons 1 empty))))))

(define (build-input n)
  (cond 
    [(< n 1) empty]
    [else (m-cons n (build-input (- n 1)))]))

;; ==================================================

;; build-trivial-input builds a formatted list of n 1's

(module+ test
  (check-equal? (print-list-from-delayed-list 
                 (build-trivial-input 3))
                (print-list-from-delayed-list 
                 (m-cons 1 (m-cons 1 (m-cons 1 empty))))))

(define (build-trivial-input n)
  (cond
    [(< n 1) empty]
    [else (m-cons 1 (build-trivial-input (- n 1)))]))

(define (build-trivial-input-2 n)
  (cond [(< n 1) empty]
        [else (m-cons 0 (build-trivial-input (- n 1)))]))

;; ==================================================

;; build-sorted-input builds a formatted list from n to m

(module+ test
  (check-equal? (print-list-from-delayed-list 
                 (build-sorted-input 2 4))
                (print-list-from-delayed-list 
                 (m-cons 2 (m-cons 3 (m-cons 4 empty))))))

(define (build-sorted-input n m)
  (cond
    [(> n m) empty]
    [else (m-cons n (build-sorted-input (+ n 1) m))]))

;; ==================================================

;; build-random-input builds a formatted list of n random numbers

(define (build-random-input n)
  (cond 
    [(< n 1) empty]
    [else (m-cons (random 100)
                  (build-random-input (- n 1)))]))

;; ====================== Unformatted Lists ============================

;; build-trivial-list builds a list of n singleton lists 
;; consisting of the element 1.

(module+ test
  (check-equal? (build-trivial-list 10)
                '((1) (1) (1) (1) (1) (1) (1) (1) (1) (1))))

(define (build-trivial-list n)
  (cond
    [(< n 1) empty]
    [else (cons (cons 1 empty) (build-trivial-list (- n 1)))]))

;; ==================================================

;; build-list builds a list of n singleton lists 
;; consisting of the elements n through 1.

(module+ test
  (check-equal? (build-list 10)
                '((10) (9) (8) (7) (6) (5) (4) (3) (2) (1))))

(define (build-list n)
  (cond
    [(< n 1) empty]
    [else (cons (cons n empty) (build-list (- n 1)))]))

;; ======================= Print Cells ===========================

;; print cells prints the cells table in a sane way
(define (print-cells)
  (hash-map *cells* (λ (a b) (when (number? (unbox (cell-box b)))
                               (cons a (unbox (cell-box b)))))))

;; ======================= Mutation =======================

;; mutate-elements-random replaces the first n elements of the given 
;; formatted input list (m-cons) with random numbers (random 100).
;; NOTE: This will only work if the input list is the first list in
;; the *cells* table

(define (mutate-elements-random n)
  (mutate-elements-random-helper n 1))

(define (mutate-elements-random-helper n m)
  (cond 
    [(< n 1) (set-cell! m (random 100))]
    [else 
     (begin (set-cell! m (random 100))
            (mutate-elements-random-helper (- n 1) (+ m 2)))]))