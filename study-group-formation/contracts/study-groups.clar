;; Study Group Formation Contract
;; Decentralized study group creation and member management

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-unauthorized (err u101))
(define-constant err-group-full (err u102))
(define-constant err-already-member (err u103))
(define-constant err-not-member (err u104))
(define-constant err-invalid-input (err u105))
(define-constant err-session-not-found (err u106))
(define-constant err-invalid-rating (err u107))
(define-constant err-already-rated (err u108))