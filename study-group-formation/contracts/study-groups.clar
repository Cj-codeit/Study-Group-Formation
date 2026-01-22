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

;; Data Variables
(define-data-var group-nonce uint u0)
(define-data-var session-nonce uint u0)

;; Data Maps
(define-map study-groups
  uint
  {
    name: (string-ascii 100),
    subject: (string-ascii 100),
    creator: principal,
    max-members: uint,
    current-members: uint,
    meeting-schedule: (string-ascii 200),
    active: bool
  }
)

(define-map group-members
  { group-id: uint, member: principal }
  {
    joined-at: uint,
    role: (string-ascii 20),
    active: bool
  }
)

(define-map user-groups-count principal uint)

(define-map study-sessions
  uint
  {
    group-id: uint,
    session-name: (string-ascii 100),
    date: uint,
    duration: uint,
    completed: bool
  }
)

(define-map session-attendance
  { session-id: uint, member: principal }
  bool
)

(define-map member-ratings
  { group-id: uint, rater: principal, rated: principal }
  {
    rating: uint,
    timestamp: uint
  }
)

(define-map group-resources
  { group-id: uint, resource-id: uint }
  {
    title: (string-ascii 100),
    url: (string-ascii 200),
    added-by: principal,
    added-at: uint
  }
)