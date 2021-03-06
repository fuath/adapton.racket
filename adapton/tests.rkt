#lang racket

;; This file contains a number of tests for adapton.
;; definitions of input lists are placed inside the test-suites
;; to prevent tables from interfering with one another,
;; and each test-suite begins by purging all tables.

(require rackunit
         rackunit/text-ui
         "merge-sort.rkt"
         "adapton.rkt"
         "tools-for-testing.rkt"
         "data-structures.rkt"
         "memo-table-modification-tools.rkt")

;; =============================================================================

;; test several adapton functions and ensure mergesort is working properly
(define correctness-tests
  (test-suite
   "testing correctness of mergesort for adapton"
   
   #:before (lambda () (displayln "Beginning correctness tests"))
   #:after  (lambda () (displayln "Correctness tests finished"))
   
   ;; housekeeping
   (hash-clear! *memo-table*)
   (hash-clear! *cells*)
   (set-box! cell-counter 0)
   (set-box! stack '())
   
   ;; define some cells
   (let* ([simple-input (make-cell 
                         (cons (cons (make-cell 9) empty)
                               (make-cell
                                (cons (cons (make-cell 6) empty)
                                      (make-cell 
                                       (cons (cons (make-cell 3) empty)
                                             empty))))))]
          [medium-input (m-cons 4 (m-cons 2 (m-cons 6 (m-cons 1 empty))))]
          [bigger-input (build-input 10)]
          [trivial-input (build-trivial-input 10)]
          [n1 (merge-sort simple-input)]
          [n2 (merge-sort medium-input)]
          [n3 (merge-sort bigger-input)]
          [n4 (merge-sort trivial-input)])
     
     (test-case
      "test that cells are being created properly"
      (check-equal? (unbox (cell-box (hash-ref *cells* 3))) 3))
     (test-case
      "test the read-cell function"
      (check-equal? (read-cell (hash-ref *cells* 2)) 6))
     (test-case
      "read-cell/update should throw an exn when there is nothing on the stack"
      (check-exn exn:fail? (λ () (read-cell/update (hash-ref *cells* 1)))))
     (test-case
      "test forcing a cell"
      (check-equal? (force (car (car (force simple-input)))) 9))
     (test-case
      "test forcing a cell deeper in a list"
      (check-equal? (force (car (car (force (cdr (force simple-input)))))) 6))
     (test-case
      "test that list is properly strutured"
      (check-equal? (print-list-from-delayed-list simple-input) '((9) (6) (3))))
     (test-case
      "test-mergesort on short list"
      (check-equal? (get-list-from-mergesort (force n1))
                    '(3 6 9)))
     (test-case
      "test mergesort on medium list"
      (check-equal? (get-list-from-mergesort (force n2))
                    '(1 2 4 6)))
     (test-case
      "test set-cell!"
      (check-not-exn (λ () (set-cell! 1 0))))
     (test-case
      "test effect of set-cell!"
      (check-equal? (unbox (cell-box (hash-ref *cells* 1))) 0))
     (test-case
      "test set-cell! is properly dirtying predecessors"
      (check-equal? (andmap node-dirty 
                            (map (λ (a) (hash-ref *memo-table* a))
                                 (cell-predecessors (hash-ref *cells* 1)))) #t))
     (test-case
      "test rebuild list after mutation of input"
      (check-equal? 
       (get-list-from-mergesort 
        (force (hash-ref *memo-table* (node-id n1))))
       '(0 3 6))))))

;; =============================================================================

(define timed-tests-0
  (test-suite
   "testing time to sort a 10 element list,~n 
    worst case (reverse-sorted)~n"
   
   #:before (lambda () (displayln "--> testing time to sort a 10 element list,
--> worst case (reverse-sorted)"))
   #:after  (lambda () (displayln "timed-tests-1 tests finished"))
   
   ;; housekeeping
   (hash-clear! *memo-table*)
   (hash-clear! *cells*)
   (set-box! cell-counter 0)
   (set-box! stack '())
   
   ;; define our test input
   (let* ([t (build-input 3)]
          [t_2 (merge-sort t)])
     
     ;; define our expected outputs
     ;; list '(1 2 3 ... 9 10)
     (define (foo m n)
       (cond
         [(> m n) empty]
         [else (cons m (foo (+ 1 m) n))]))
     
     (displayln "--> time to sort")
     (check-equal? (time (get-list-from-mergesort (force t_2)))
                   (foo 1 3))
     (displayln "--> time to compute a second time")
     (check-equal? (time (get-list-from-mergesort (force t_2)))
                   (foo 1 3))
     (set-cell! 1 0)
     (displayln "--> time to re-sort after mutation")
     (check-equal? (time (get-list-from-mergesort 
                          (force (hash-ref *memo-table* (node-id t_2)))))
                   (cons 0 (remove 1 (foo 1 3)))))))

;; =============================================================================

(define timed-tests-1
  (test-suite
   "testing time to sort a 1000 element list,~n 
    worst case (reverse-sorted)~n"
   
   #:before (lambda () (displayln "--> testing time to sort a 1000 element list,
--> worst case (reverse-sorted)"))
   #:after  (lambda () (displayln "timed-tests-1 tests finished"))
   
   ;; housekeeping
   (hash-clear! *memo-table*)
   (hash-clear! *cells*)
   (set-box! cell-counter 0)
   (set-box! stack '())
   
   ;; define our test input
   (let* ([t (build-input 1000)]
          [t_2 (merge-sort t)])
     
     ;; define our expected outputs
     ;; list '(1 2 3 ... 999 1000)
     (define (foo m n)
       (cond
         [(> m n) empty]
         [else (cons m (foo (+ 1 m) n))]))
     
     (displayln "--> time to sort")
     (check-equal? (time (get-list-from-mergesort (force t_2)))
                   (foo 1 1000))
     (displayln "--> time to compute a second time")
     (check-equal? (time (get-list-from-mergesort (force t_2)))
                   (foo 1 1000))
     (set-cell! 1 0)
     (displayln "--> time to re-sort after mutation")
     (check-equal? (time (get-list-from-mergesort 
                          (force (hash-ref *memo-table* (node-id t_2)))))
                   (cons 0 (remove 1 (foo 1 1000)))))))

;; =============================================================================

(define timed-tests-2
  (test-suite
   "testing time to get the first element from a 1000 element list,~n 
    worst case (reverse-sorted)~n"
   
   #:before (lambda () (displayln "--> testing time to get first from 1000 element list,
--> worst case (reverse-sorted)"))
   #:after  (lambda () (displayln "timed-tests-2 tests finished"))
   
   ;; housekeeping
   (hash-clear! *memo-table*)
   (hash-clear! *cells*)
   (set-box! cell-counter 0)
   (set-box! stack '())
   
   ;; define our test input
   (let* ([t (build-input 1000)]
          [t_2 (merge-sort t)])
     
     (displayln "--> time to get first element")
     (check-equal? (time (force (car (force t_2))))
                   1)
     (displayln "--> time to compute a second time")
     (check-equal? (time (force (car (force t_2))))
                   1)
     (set-cell! 1 0)
     (displayln "--> time to get new first element after mutation")
     (check-equal? (time (force (car (force (hash-ref *memo-table* 
                                                      (node-id t_2))))))
                   0))))

;; =============================================================================

(define timed-tests-3
  (test-suite
   "testing time to sort a 10000 element list,~n 
    worst case (reverse-sorted)~n"
   
   #:before (lambda () (displayln "--> testing time to sort a 10000 element list,
--> worst case (reverse-sorted)"))
   #:after  (lambda () (displayln "timed-tests-3 tests finished"))
   
   ;; housekeeping
   (hash-clear! *memo-table*)
   (hash-clear! *cells*)
   (set-box! cell-counter 0)
   (set-box! stack '())
   
   ;; define our test input
   (let* ([t (build-input 10000)]
          [t_2 (merge-sort t)])
     
     ;; define our expected outputs
     ;; list '(1 2 3 ... 9999 10000)
     (define (foo m n)
       (cond
         [(> m n) empty]
         [else (cons m (foo (+ 1 m) n))]))
     
     (displayln "--> time to sort")
     (check-equal? (time (get-list-from-mergesort (force t_2)))
                   (foo 1 10000))
     (displayln "--> time to compute a second time")
     (check-equal? (time (get-list-from-mergesort (force t_2)))
                   (foo 1 10000))
     (set-cell! 1 0)
     (displayln "--> time to re-sort after mutation")
     (check-equal? (time (get-list-from-mergesort 
                          (force (hash-ref *memo-table* (node-id t_2)))))
                   (cons 0 (remove 1 (foo 1 10000)))))))

;; =============================================================================

(define timed-tests-4
  (test-suite
   "testing time to sort a 10000 element list,~n 
    worst case (reverse-sorted)~n"
   
   #:before (lambda () (displayln "--> testing time to sort a 10000 element list,
--> worst case (reverse-sorted)"))
   #:after  (lambda () (displayln "timed-tests-4 tests finished"))
   
   ;; housekeeping
   (hash-clear! *memo-table*)
   (hash-clear! *cells*)
   (set-box! cell-counter 0)
   (set-box! stack '())
   
   ;; define our test input
   (let* ([t (build-input 10000)]
          [t_2 (merge-sort t)])
     
     (displayln "--> time to get first element")
     (check-equal? (time (force (car (force t_2))))
                   1)
     (displayln "--> time to compute a second time")
     (check-equal? (time (force (car (force t_2))))
                   1)
     (set-cell! 1 0)
     (displayln "--> time to get new first element after mutation")
     (check-equal? (time (force (car (force (hash-ref *memo-table* 
                                                      (node-id t_2))))))
                   0))))

;; =============================================================================

;; --- warning, these tests are VERY BIG ---
(define timed-tests-5
  (test-suite
   "testing time to sort a 100000 element list,~n 
    worst case (reverse-sorted)~n"
   
   #:before (lambda () (displayln "--> testing time to sort a 100000 element list,
--> worst case (reverse-sorted)"))
   #:after  (lambda () (displayln "timed-tests-5 tests finished"))
   
   ;; housekeeping
   (hash-clear! *memo-table*)
   (hash-clear! *cells*)
   (set-box! cell-counter 0)
   (set-box! stack '())
   
   ;; define our test input
   (let* ([t (build-input 100000)]
          [t_2 (merge-sort t)])
     
     ;; define our expected outputs
     ;; list '(1 2 3 ... 9999 10000)
     (define (foo m n)
       (cond
         [(> m n) empty]
         [else (cons m (foo (+ 1 m) n))]))
     
     (displayln "--> time to sort")
     (check-equal? (time (get-list-from-mergesort (force t_2)))
                   (foo 1 100000))
     (displayln "--> time to compute a second time")
     (check-equal? (time (get-list-from-mergesort (force t_2)))
                   (foo 1 100000))
     (set-cell! 1 0)
     (displayln "--> time to re-sort after mutation")
     (check-equal? (time (get-list-from-mergesort 
                          (force (hash-ref *memo-table* (node-id t_2)))))
                   (cons 0 (remove 1 (foo 1 100000)))))))

;; =============================================================================

;; --- warning, these tests are VERY BIG ---
(define timed-tests-6
  (test-suite
   "testing time to get the first element of a 100000 element list,~n 
    worst case (reverse-sorted)~n"
   
   #:before (lambda () (displayln "--> testing time to sort a 100000 element list,
--> worst case (reverse-sorted)"))
   #:after  (lambda () (displayln "timed-tests-6 tests finished"))
   
   ;; housekeeping
   (hash-clear! *memo-table*)
   (hash-clear! *cells*)
   (set-box! cell-counter 0)
   (set-box! stack '())
   
   ;; define our test input
   (let* ([t (build-input 100000)]
          [t_2 (merge-sort t)])
     
     (displayln "--> time to get first element")
     (check-equal? (time (force (car (force t_2))))
                   1)
     (displayln "--> time to compute a second time")
     (check-equal? (time (force (car (force t_2))))
                   1)
     (set-cell! 1 0)
     (displayln "--> time to get new first element after mutation")
     (check-equal? (time (force (car (force (hash-ref *memo-table* 
                                                      (node-id t_2))))))
                   0))))

;; =============================================================================

(define timed-tests-7
  (test-suite
   "testing time to get the first element of a 1000 element list,
    trivial case all 1's"
   
   #:before (lambda () (displayln "--> testing time to sort a 1000 element list,
--> trivial case (all 1's)"))
   #:after  (lambda () (displayln "timed-tests-7 tests finished"))
   
   ;; housekeeping
   (hash-clear! *memo-table*)
   (hash-clear! *cells*)
   (set-box! cell-counter 0)
   (set-box! stack '())
   
   ;; define our test input
   (let* ([t (build-trivial-input 1000)]
          [t_2 (merge-sort t)])
     
     (displayln "--> time to get first element")
     (check-equal? (time (force (car (force t_2))))
                   1)
     (displayln "--> time to compute a second time")
     (check-equal? (time (force (car (force t_2))))
                   1)
     (set-cell! 1 0)
     (displayln "--> time to get new first element after mutation")
     (check-equal? (time (force (car (force (hash-ref *memo-table*
                                                      (node-id t_2))))))
                   0))))

;; =============================================================================

(define timed-tests-8
  (test-suite
   "this test will sort a list and then sort it again with a large number of
the elements in the list randomly mutated."
   
   #:before (lambda () (displayln "--> testing time to sort a 1000 element list,
--> random case"))
   #:after  (lambda () (displayln "timed-tests-8 tests finished"))
   
   ;; housekeeping
   (hash-clear! *memo-table*)
   (hash-clear! *cells*)
   (set-box! cell-counter 0)
   (set-box! stack '())
   
   ;; define our test input
   (let* ([t (build-random-input 1000)]
          [t_2 (merge-sort t)])
     
     (displayln "--> time to sort the list")
     (check-equal? 
      (list? (time (get-list-from-mergesort (force t_2))))
      #t)
     (displayln "--> time to compute a second time")
     (check-equal? 
      (list? (time (get-list-from-mergesort (force t_2))))
      #t)
     (mutate-elements-random 500)
     (displayln "--> time to sort again after mutation")
     (check-equal? 
      (list? (time (get-list-from-mergesort 
                    (force (hash-ref *memo-table* (node-id t_2))))))
      #t))))

;; =============================================================================

;; bizzare bug.....
(define trivial-tests-1
  (test-suite
   "testing to ensure bug with list of 1's doesn't happen"
   
   ;; housekeeping
   (hash-clear! *memo-table*)
   (hash-clear! *cells*)
   (set-box! cell-counter 0)
   (set-box! stack '())
   
   ;; define our test input
   (let* ([t (build-trivial-input 89)]
          [t_2 (merge-sort t)])
     
     (check-equal? (force (car (force t_2)))
                   1)
     (set-cell! 1 0)
     (check-equal? (force (car (force (hash-ref *memo-table*
                                                (node-id t_2)))))
                   0))))

(define trivial-tests-2
  (test-suite
   "testing to ensure bug with list of 1's does happen"
   
   ;; housekeeping
   (hash-clear! *memo-table*)
   (hash-clear! *cells*)
   (set-box! cell-counter 0)
   (set-box! stack '())
   
   ;; define our test input
   (let* ([t (build-trivial-input 90)]
          [t_2 (merge-sort t)])
     
     (check-equal? (force (car (force t_2)))
                   1)
     (set-cell! 1 0)
     (check-equal? (force (car (force (hash-ref *memo-table*
                                                (node-id t_2)))))
                   0))))

(define trivial-tests-3
  (test-suite
   "testing to ensure bug with list of 1's does happen"
   
   ;; housekeeping
   (hash-clear! *memo-table*)
   (hash-clear! *cells*)
   (set-box! cell-counter 0)
   (set-box! stack '())
   
   ;; define our test input
   (let* ([t (build-trivial-input 90)]
          [t_2 (merge-sort t)])
     
     (check-equal? (force (car (force t_2)))
                   1)
     (set-cell! 3 0)
     (check-equal? (force (car (force (hash-ref *memo-table*
                                                (node-id t_2)))))
                   0))))

(define (run-all-tests)
  (displayln "running correctness tests")
  (run-tests correctness-tests)
  (displayln "running timed tests")
  (run-tests timed-tests-1)
  (run-tests timed-tests-2)
  (run-tests timed-tests-3)
  (run-tests timed-tests-4)
  ;(run-tests timed-tests-5)
  ;(run-tests timed-tests-6)
  (run-tests timed-tests-7)
  (run-tests timed-tests-8)
  (displayln "running trivial-tests")
  (run-tests trivial-tests-1)
  (run-tests trivial-tests-2)
  (run-tests trivial-tests-3))